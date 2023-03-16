import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { GlButton, GlFormCheckbox, GlFormInput, GlFormInputGroup, GlDatepicker } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { TEST_HOST } from 'helpers/test_constants';
import NewDeployToken from '~/deploy_tokens/components/new_deploy_token.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert, VARIANT_INFO } from '~/alert';

const createNewTokenPath = `${TEST_HOST}/create`;
const deployTokensHelpUrl = `${TEST_HOST}/help`;

jest.mock('~/alert');

describe('New Deploy Token', () => {
  let wrapper;

  const factory = (options = {}) => {
    const defaults = {
      containerRegistryEnabled: true,
      packagesRegistryEnabled: true,
      tokenType: 'project',
    };
    const { containerRegistryEnabled, packagesRegistryEnabled, tokenType } = {
      ...defaults,
      ...options,
    };
    return shallowMount(NewDeployToken, {
      propsData: {
        deployTokensHelpUrl,
        containerRegistryEnabled,
        packagesRegistryEnabled,
        createNewTokenPath,
        tokenType,
      },
      stubs: {
        GlFormCheckbox,
      },
    });
  };

  describe('without a container registry', () => {
    beforeEach(() => {
      wrapper = factory({ containerRegistryEnabled: false });
    });

    it('should not show the read registry scope', () => {
      wrapper
        .findAllComponents(GlFormCheckbox)
        .wrappers.forEach((checkbox) => expect(checkbox.text()).not.toBe('read_registry'));
    });
  });

  describe('with a container registry', () => {
    beforeEach(() => {
      wrapper = factory();
    });

    it('should show the read registry scope', () => {
      const checkbox = wrapper.findAllComponents(GlFormCheckbox).at(1);
      expect(checkbox.text()).toContain('read_registry');
    });

    function submitTokenThenCheck() {
      wrapper.findAllComponents(GlButton).at(0).vm.$emit('click');

      return waitForPromises()
        .then(() => nextTick())
        .then(() => {
          const [tokenUsername, tokenValue] = wrapper.findAllComponents(GlFormInputGroup).wrappers;

          expect(tokenUsername.props('value')).toBe('test token username');
          expect(tokenValue.props('value')).toBe('test token');

          expect(createAlert).toHaveBeenCalledWith(
            expect.objectContaining({
              variant: VARIANT_INFO,
            }),
          );
        });
    }

    it('should alert error message if token creation fails', async () => {
      const mockAxios = new MockAdapter(axios);

      const date = new Date();
      const formInputs = wrapper.findAllComponents(GlFormInput);
      const name = formInputs.at(0);
      const username = formInputs.at(2);
      name.vm.$emit('input', 'test name');
      username.vm.$emit('input', 'test username');

      const datepicker = wrapper.findAllComponents(GlDatepicker).at(0);
      datepicker.vm.$emit('input', date);

      const [
        readRepo,
        readRegistry,
        writeRegistry,
        readPackageRegistry,
        writePackageRegistry,
      ] = wrapper.findAllComponents(GlFormCheckbox).wrappers;
      readRepo.vm.$emit('input', true);
      readRegistry.vm.$emit('input', true);
      writeRegistry.vm.$emit('input', true);
      readPackageRegistry.vm.$emit('input', true);
      writePackageRegistry.vm.$emit('input', true);

      const expectedErrorMessage = 'Server error while creating a token';

      mockAxios
        .onPost(createNewTokenPath, {
          deploy_token: {
            name: 'test name',
            expires_at: date.toISOString(),
            username: 'test username',
            read_repository: true,
            read_registry: true,
            write_registry: true,
            read_package_registry: true,
            write_package_registry: true,
          },
        })
        .replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, { message: expectedErrorMessage });

      wrapper.findAllComponents(GlButton).at(0).vm.$emit('click');

      await waitForPromises().then(() => nextTick());

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: expectedErrorMessage,
        }),
      );
    });

    it('should make a request to create a token on submit', () => {
      const mockAxios = new MockAdapter(axios);

      const date = new Date();
      const formInputs = wrapper.findAllComponents(GlFormInput);
      const name = formInputs.at(0);
      const username = formInputs.at(2);
      name.vm.$emit('input', 'test name');
      username.vm.$emit('input', 'test username');

      const datepicker = wrapper.findAllComponents(GlDatepicker).at(0);
      datepicker.vm.$emit('input', date);

      const [
        readRepo,
        readRegistry,
        writeRegistry,
        readPackageRegistry,
        writePackageRegistry,
      ] = wrapper.findAllComponents(GlFormCheckbox).wrappers;
      readRepo.vm.$emit('input', true);
      readRegistry.vm.$emit('input', true);
      writeRegistry.vm.$emit('input', true);
      readPackageRegistry.vm.$emit('input', true);
      writePackageRegistry.vm.$emit('input', true);

      mockAxios
        .onPost(createNewTokenPath, {
          deploy_token: {
            name: 'test name',
            expires_at: date.toISOString(),
            username: 'test username',
            read_repository: true,
            read_registry: true,
            write_registry: true,
            read_package_registry: true,
            write_package_registry: true,
          },
        })
        .replyOnce(HTTP_STATUS_OK, { username: 'test token username', token: 'test token' });

      return submitTokenThenCheck();
    });

    it('should request a token without an expiration date', () => {
      const mockAxios = new MockAdapter(axios);

      const formInputs = wrapper.findAllComponents(GlFormInput);
      const name = formInputs.at(0);
      const username = formInputs.at(2);
      name.vm.$emit('input', 'test never expire name');
      username.vm.$emit('input', 'test never expire username');

      const [, , , readPackageRegistry, writePackageRegistry] = wrapper.findAllComponents(
        GlFormCheckbox,
      ).wrappers;
      readPackageRegistry.vm.$emit('input', true);
      writePackageRegistry.vm.$emit('input', true);

      mockAxios
        .onPost(createNewTokenPath, {
          deploy_token: {
            name: 'test never expire name',
            expires_at: null,
            username: 'test never expire username',
            read_repository: false,
            read_registry: false,
            write_registry: false,
            read_package_registry: true,
            write_package_registry: true,
          },
        })
        .replyOnce(HTTP_STATUS_OK, { username: 'test token username', token: 'test token' });

      return submitTokenThenCheck();
    });
  });

  describe('help text for write_package_registry scope', () => {
    const findWriteRegistryScopeCheckbox = () => wrapper.findAllComponents(GlFormCheckbox).at(4);

    describe('with project tokenType', () => {
      beforeEach(() => {
        wrapper = factory();
      });

      it('should show the correct help text', () => {
        expect(findWriteRegistryScopeCheckbox().text()).toContain(
          'Allows read, write and delete access to the package registry.',
        );
      });
    });

    describe('with group tokenType', () => {
      beforeEach(() => {
        wrapper = factory({ tokenType: 'group' });
      });

      it('should show the correct help text', () => {
        expect(findWriteRegistryScopeCheckbox().text()).toContain(
          'Allows read and write access to the package registry.',
        );
      });
    });
  });
});
