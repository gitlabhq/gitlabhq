import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { GlButton, GlFormCheckbox, GlFormInput, GlFormInputGroup, GlDatepicker } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { TEST_HOST } from 'helpers/test_constants';
import NewDeployToken from '~/deploy_tokens/components/new_deploy_token.vue';
import waitForPromises from 'helpers/wait_for_promises';

const createNewTokenPath = `${TEST_HOST}/create`;
const deployTokensHelpUrl = `${TEST_HOST}/help`;
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
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

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
      expect(checkbox.text()).toBe('read_registry');
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

      const [readRepo, readRegistry] = wrapper.findAllComponents(GlFormCheckbox).wrappers;
      readRepo.vm.$emit('input', true);
      readRegistry.vm.$emit('input', true);

      mockAxios
        .onPost(createNewTokenPath, {
          deploy_token: {
            name: 'test name',
            expires_at: date.toISOString(),
            username: 'test username',
            read_repository: true,
            read_registry: true,
          },
        })
        .replyOnce(200, { username: 'test token username', token: 'test token' });

      wrapper.findAllComponents(GlButton).at(0).vm.$emit('click');

      return waitForPromises()
        .then(() => nextTick())
        .then(() => {
          const [tokenUsername, tokenValue] = wrapper.findAllComponents(GlFormInputGroup).wrappers;

          expect(tokenUsername.props('value')).toBe('test token username');
          expect(tokenValue.props('value')).toBe('test token');
        });
    });
  });
});
