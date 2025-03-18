import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlButton, GlForm, GlFormInput } from '@gitlab/ui';
import updateDockerHubCredentialsMutationErrorPayload from 'test_fixtures/graphql/packages_and_registries/settings/group/graphql/mutations/update_docker_hub_credentials.mutation.graphql.field_errors.json';
import updateDockerHubCredentialsMutationServerErrorPayload from 'test_fixtures/graphql/packages_and_registries/settings/group/graphql/mutations/update_docker_hub_credentials.mutation.graphql.server_errors.json';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import DockerHubAuthenticationSection from '~/packages_and_registries/settings/group/components/docker_hub_authentication_section.vue';
import updateDockerHubCredentialsMutation from '~/packages_and_registries/settings/group/graphql/mutations/update_docker_hub_credentials.mutation.graphql';
import {
  dependencyProxySettings as dependencyProxySettingsMock,
  dependencyProxySettingMutationMock,
} from '../mock_data';

describe('DockerHubAuthenticationSection', () => {
  let wrapper;
  let apolloProvider;

  const defaultProvide = {
    groupPath: 'foo_group_path',
  };

  Vue.use(VueApollo);

  const mountComponent = ({
    provide = defaultProvide,
    formData = dependencyProxySettingsMock(),
    updateDockerHubCredentialsMutationResolver = jest.fn().mockResolvedValue(
      dependencyProxySettingMutationMock({
        identity: 'foobar',
      }),
    ),
  } = {}) => {
    const requestHandlers = [
      [updateDockerHubCredentialsMutation, updateDockerHubCredentialsMutationResolver],
    ];

    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(DockerHubAuthenticationSection, {
      apolloProvider,
      provide,
      propsData: {
        formData,
      },
    });
  };

  const findHeader = () => wrapper.find('h3');
  const findForm = () => wrapper.findComponent(GlForm);
  const findIdentityInput = () => wrapper.findAllComponents(GlFormInput).at(0);
  const findSecretInput = () => wrapper.findAllComponents(GlFormInput).at(1);
  const findDescription = () => wrapper.findByTestId('description');
  const findSubmitButton = () => wrapper.findComponent(GlButton);

  it('renders the section header & description', () => {
    mountComponent();

    expect(findHeader().text()).toBe('Docker Hub authentication');
    expect(findDescription().text()).toBe(
      'Credentials used to authenticate with Docker Hub when pulling images.',
    );
  });

  it('renders submit button', () => {
    mountComponent();

    expect(findSubmitButton().text()).toBe('Save changes');
    expect(findSubmitButton().attributes('disabled')).toBeUndefined();
    expect(findSubmitButton().props('loading')).toBe(false);
  });

  describe('form fields', () => {
    describe('form field "identity"', () => {
      it('exists', () => {
        mountComponent();

        expect(findIdentityInput().exists()).toBe(true);
      });
    });

    describe('form field "secret"', () => {
      it('exists', () => {
        mountComponent();

        expect(findSecretInput().exists()).toBe(true);
      });
    });
  });

  describe('when graphql mutation is in progress', () => {
    beforeEach(async () => {
      mountComponent();

      await findIdentityInput().vm.$emit('input', 'foobar');
      await findSecretInput().vm.$emit('input', 'secret');
      findForm().vm.$emit('submit', { preventDefault: jest.fn() });
    });

    it('displays a loading spinner', () => {
      expect(findSubmitButton().props('loading')).toBe(true);
    });
  });

  describe('submit a new rule', () => {
    const findAlert = () => wrapper.findComponent(GlAlert);

    const submitForm = async () => {
      await findIdentityInput().vm.$emit('input', 'foobar');
      await findSecretInput().vm.$emit('input', 'secret');
      await findForm().vm.$emit('submit', { preventDefault: jest.fn() });
      await waitForPromises();
    };

    it('dispatches correct apollo mutation', async () => {
      const updateDockerHubCredentialsMutationResolver = jest
        .fn()
        .mockResolvedValue(dependencyProxySettingsMock());

      mountComponent({ updateDockerHubCredentialsMutationResolver });

      await submitForm();

      expect(updateDockerHubCredentialsMutationResolver).toHaveBeenCalledWith({
        input: { groupPath: 'foo_group_path', identity: 'foobar', secret: 'secret' },
      });
    });

    it('emits event "success" when apollo mutation successful', async () => {
      mountComponent();

      await submitForm();

      expect(wrapper.emitted('success')).toBeDefined();
    });

    it('sets placeholder on secret input field', async () => {
      mountComponent({
        formData: {},
      });

      expect(findSecretInput().props('placeholder')).toBe('');
      await submitForm();
      expect(findSecretInput().props('value')).toBe(null);
      expect(findSecretInput().props('placeholder')).toBe('*****');
    });

    describe.each`
      description                      | updateDockerHubCredentialsMutationResolver                                           | expectedErrorMessage
      ${'responds with field errors'}  | ${jest.fn().mockResolvedValue(updateDockerHubCredentialsMutationErrorPayload)}       | ${"Secret can't be blank"}
      ${'responds with server errors'} | ${jest.fn().mockResolvedValue(updateDockerHubCredentialsMutationServerErrorPayload)} | ${"The resource that you are attempting to access does not exist or you don't have permission to perform this action"}
      ${'fails with network error'}    | ${jest.fn().mockRejectedValue(new Error('GraphQL error'))}                           | ${'GraphQL error'}
    `(
      'when apollo mutation request $description',
      ({ updateDockerHubCredentialsMutationResolver, expectedErrorMessage }) => {
        beforeEach(async () => {
          mountComponent({
            updateDockerHubCredentialsMutationResolver,
          });

          await submitForm();
        });

        it('shows error alert with correct message', () => {
          expect(findAlert().text()).toBe(expectedErrorMessage);
        });
      },
    );
  });
});
