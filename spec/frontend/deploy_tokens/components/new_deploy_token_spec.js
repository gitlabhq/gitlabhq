import { shallowMount } from '@vue/test-utils';
import {
  GlAlert,
  GlButton,
  GlFormCheckbox,
  GlFormInput,
  GlFormInputGroup,
  GlDatepicker,
} from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { TEST_HOST } from 'helpers/test_constants';
import NewDeployToken from '~/deploy_tokens/components/new_deploy_token.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
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
        GlAlert,
        GlFormCheckbox,
      },
    });
  };

  const findNewTokenAlert = () => wrapper.findComponent(GlAlert);
  const findClipboardButtons = () => wrapper.findAllComponents(ClipboardButton);
  const findAllCheckboxes = () => wrapper.findAllComponents(GlFormCheckbox);
  const findFormInputs = () => wrapper.findAllComponents(GlFormInput);

  const setScopeCheckboxes = ({
    readRepoValue = true,
    readRegistryValue = true,
    writeRegistryValue = true,
    readPackageRegistryValue = true,
    writePackageRegistryValue = true,
  } = {}) => {
    const [readRepo, readRegistry, writeRegistry, readPackageRegistry, writePackageRegistry] =
      findAllCheckboxes().wrappers;

    readRepo.vm.$emit('input', readRepoValue);
    readRegistry.vm.$emit('input', readRegistryValue);
    writeRegistry.vm.$emit('input', writeRegistryValue);
    readPackageRegistry.vm.$emit('input', readPackageRegistryValue);
    writePackageRegistry.vm.$emit('input', writePackageRegistryValue);
  };

  const setTokenName = ({ nameVal = 'test name', usernameVal = 'test username' } = {}) => {
    const formInputs = findFormInputs();
    formInputs.at(0).vm.$emit('input', nameVal);
    formInputs.at(2).vm.$emit('input', usernameVal);
  };

  const setTokenForm = ({ date }) => {
    setTokenName();

    const datepicker = wrapper.findAllComponents(GlDatepicker).at(0);
    datepicker.vm.$emit('input', date);

    setScopeCheckboxes();
  };

  const submitToken = async () => {
    wrapper.findAllComponents(GlButton).at(0).vm.$emit('click');
    await waitForPromises();
  };

  const checkSubmittedToken = () => {
    const [tokenUsername, tokenValue] = wrapper.findAllComponents(GlFormInputGroup).wrappers;

    expect(tokenUsername.props('value')).toBe('test token username');
    expect(tokenValue.props('value')).toBe('test token');

    expect(createAlert).toHaveBeenCalledWith(
      expect.objectContaining({
        variant: VARIANT_INFO,
      }),
    );
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
      const checkbox = findAllCheckboxes().at(1);
      expect(checkbox.text()).toContain('read_registry');
    });
  });

  describe('token submission', () => {
    let mockAxios;
    const defaultTokenPayload = {
      name: 'test name',
      username: 'test username',
      read_repository: true,
      read_registry: true,
      write_registry: true,
      read_package_registry: true,
      write_package_registry: true,
    };

    const mockTokenRequest = ({ payload, status, response }) => {
      mockAxios.onPost(createNewTokenPath, { deploy_token: payload }).replyOnce(status, response);
    };

    beforeEach(() => {
      mockAxios = new MockAdapter(axios);
      wrapper = factory();
    });

    it('should alert error message if token creation fails', async () => {
      const message = 'Server error while creating a token';
      const date = new Date();

      setTokenForm({ date });
      mockTokenRequest({
        payload: {
          ...defaultTokenPayload,
          expires_at: date.toISOString(),
        },
        status: HTTP_STATUS_INTERNAL_SERVER_ERROR,
        response: { message },
      });

      await submitToken();

      expect(createAlert).toHaveBeenCalledWith(expect.objectContaining({ message }));
    });

    it('should make a request to create a token on submit', async () => {
      const date = new Date();

      setTokenForm({ date });
      mockTokenRequest({
        payload: {
          ...defaultTokenPayload,
          expires_at: date.toISOString(),
        },
        status: HTTP_STATUS_OK,
        response: { username: 'test token username', token: 'test token' },
      });

      await submitToken();

      checkSubmittedToken();
    });

    it('should request a token without an expiration date', async () => {
      const nameVal = 'test never expire name';
      const usernameVal = 'test never expire username';
      const readRepoValue = false;
      const readRegistryValue = false;
      const writeRegistryValue = false;

      setTokenName({ nameVal, usernameVal });
      setScopeCheckboxes({ readRepoValue, readRegistryValue, writeRegistryValue });

      mockTokenRequest({
        payload: {
          ...defaultTokenPayload,
          expires_at: null,
          name: nameVal,
          username: usernameVal,
          read_repository: readRepoValue,
          read_registry: readRegistryValue,
          write_registry: writeRegistryValue,
        },
        status: HTTP_STATUS_OK,
        response: { username: 'test token username', token: 'test token' },
      });

      await submitToken();

      checkSubmittedToken();
    });

    it('should display the created token', async () => {
      expect(findNewTokenAlert().exists()).toBe(false);

      const date = new Date();
      setTokenForm({ date });

      mockTokenRequest({
        payload: {
          ...defaultTokenPayload,
          expires_at: date.toISOString(),
        },
        status: HTTP_STATUS_OK,
        response: { username: 'test token username', token: 'test token' },
      });

      await submitToken();

      const tokenAlert = findNewTokenAlert();
      expect(tokenAlert.exists()).toBe(true);
      expect(tokenAlert.text()).toContain('Your new deploy token');

      const [usernameBtn, tokenBtn] = findClipboardButtons().wrappers;
      expect(usernameBtn.props()).toMatchObject({
        text: 'test token username',
        title: 'Copy username',
      });
      expect(tokenBtn.props()).toMatchObject({ text: 'test token', title: 'Copy deploy token' });
    });
  });

  describe('help text for write_package_registry scope', () => {
    const findWriteRegistryScopeCheckbox = () => findAllCheckboxes().at(4);

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
