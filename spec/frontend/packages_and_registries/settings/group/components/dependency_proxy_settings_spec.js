import { GlSprintf, GlToggle } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import DependencyProxySettings from '~/packages_and_registries/settings/group/components/dependency_proxy_settings.vue';
import DockerHubAuthenticationSection from '~/packages_and_registries/settings/group/components/docker_hub_authentication_section.vue';

import {
  DEPENDENCY_PROXY_HEADER,
  DEPENDENCY_PROXY_DESCRIPTION,
} from '~/packages_and_registries/settings/group/constants';

import updateDependencyProxySettings from '~/packages_and_registries/settings/group/graphql/mutations/update_dependency_proxy_settings.mutation.graphql';
import updateDependencyProxyImageTtlGroupPolicy from '~/packages_and_registries/settings/group/graphql/mutations/update_dependency_proxy_image_ttl_group_policy.mutation.graphql';
import getGroupPackagesSettingsQuery from '~/packages_and_registries/settings/group/graphql/queries/get_group_packages_settings.query.graphql';
import SettingsSection from '~/vue_shared/components/settings/settings_section.vue';
import {
  updateGroupDependencyProxySettingsOptimisticResponse,
  updateDependencyProxyImageTtlGroupPolicyOptimisticResponse,
} from '~/packages_and_registries/settings/group/graphql/utils/optimistic_responses';
import {
  dependencyProxySettings as dependencyProxySettingsMock,
  dependencyProxyImageTtlPolicy as dependencyProxyImageTtlPolicyMock,
  dependencyProxySettingMutationMock,
  groupPackageSettingsMock,
  mutationErrorMock,
  dependencyProxyUpdateTllPolicyMutationMock,
} from 'ee_else_ce_jest/packages_and_registries/settings/group/mock_data';

jest.mock('~/alert');
jest.mock('~/packages_and_registries/settings/group/graphql/utils/optimistic_responses');

describe('DependencyProxySettings', () => {
  let wrapper;
  let apolloProvider;
  let updateSettingsMutationResolver;
  let updateTtlPoliciesMutationResolver;

  const defaultProvide = {
    groupPath: 'foo_group_path',
    groupDependencyProxyPath: 'group_dependency_proxy_path',
  };

  Vue.use(VueApollo);

  const mountComponent = ({
    provide = defaultProvide,
    isLoading = false,
    dependencyProxySettings = dependencyProxySettingsMock(),
    dependencyProxyImageTtlPolicy = dependencyProxyImageTtlPolicyMock(),
  } = {}) => {
    const requestHandlers = [
      [updateDependencyProxySettings, updateSettingsMutationResolver],
      [updateDependencyProxyImageTtlGroupPolicy, updateTtlPoliciesMutationResolver],
    ];

    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(DependencyProxySettings, {
      apolloProvider,
      provide,
      propsData: {
        dependencyProxySettings,
        dependencyProxyImageTtlPolicy,
        isLoading,
      },
      stubs: {
        GlSprintf,
        GlToggle,
      },
    });
  };

  beforeEach(() => {
    updateSettingsMutationResolver = jest
      .fn()
      .mockResolvedValue(dependencyProxySettingMutationMock());
    updateTtlPoliciesMutationResolver = jest
      .fn()
      .mockResolvedValue(dependencyProxyUpdateTllPolicyMutationMock());
  });

  const findSettingsSection = () => wrapper.findComponent(SettingsSection);
  const findDockerHubAuthenticationSection = () =>
    wrapper.findComponent(DockerHubAuthenticationSection);
  const findEnableProxyToggle = () => wrapper.findByTestId('dependency-proxy-setting-toggle');
  const findEnableTtlPoliciesToggle = () =>
    wrapper.findByTestId('dependency-proxy-ttl-policies-toggle');
  const findToggleHelpLink = () => wrapper.findByTestId('toggle-help-link');

  const fillApolloCache = () => {
    apolloProvider.defaultClient.cache.writeQuery({
      query: getGroupPackagesSettingsQuery,
      variables: {
        fullPath: defaultProvide.groupPath,
      },
      ...groupPackageSettingsMock,
    });
  };

  it('renders a settings section', () => {
    mountComponent();

    expect(findSettingsSection().exists()).toBe(true);
  });

  it('has the correct header text and description', () => {
    mountComponent();

    expect(findSettingsSection().props('heading')).toContain(DEPENDENCY_PROXY_HEADER);
    expect(findSettingsSection().props('description')).toContain(DEPENDENCY_PROXY_DESCRIPTION);
  });

  describe('enable toggle', () => {
    it('exists', () => {
      mountComponent();

      expect(findEnableProxyToggle().props()).toMatchObject({
        label: 'Enable Dependency Proxy',
      });
    });

    describe('when enabled', () => {
      beforeEach(() => {
        mountComponent();
      });

      it('has help text with a link', () => {
        expect(findEnableProxyToggle().text()).toContain(
          'To see the image prefix and what is in the cache, visit the Dependency Proxy',
        );
        expect(findToggleHelpLink().attributes()).toMatchObject({
          href: defaultProvide.groupDependencyProxyPath,
        });
      });
    });

    describe('when disabled', () => {
      beforeEach(() => {
        mountComponent({
          dependencyProxySettings: dependencyProxySettingsMock({ enabled: false }),
        });
      });

      it('the help text is not visible', () => {
        expect(findToggleHelpLink().exists()).toBe(false);
      });

      it('hides the Docker Hub authentication section', () => {
        expect(findDockerHubAuthenticationSection().exists()).toBe(false);
      });
    });
  });

  describe('Docker Hub authentication section', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('exists', () => {
      expect(findDockerHubAuthenticationSection().props('formData')).toMatchObject(
        dependencyProxySettingsMock(),
      );
    });

    it('emits a success event', () => {
      findDockerHubAuthenticationSection().vm.$emit('success');

      expect(wrapper.emitted('success')).toEqual([[]]);
    });
  });

  describe('storage settings', () => {
    describe('enable proxy ttl policies', () => {
      it('exists', () => {
        mountComponent();

        expect(findEnableTtlPoliciesToggle().props()).toMatchObject({
          help: 'Automatically remove cached images older than 90 days.',
          label: 'Automatic cache cleanup',
        });
      });
    });
  });

  describe.each`
    toggleName               | toggleFinder                   | localErrorMock                                | optimisticResponse
    ${'enable proxy'}        | ${findEnableProxyToggle}       | ${dependencyProxySettingMutationMock}         | ${updateGroupDependencyProxySettingsOptimisticResponse}
    ${'enable ttl policies'} | ${findEnableTtlPoliciesToggle} | ${dependencyProxyUpdateTllPolicyMutationMock} | ${updateDependencyProxyImageTtlGroupPolicyOptimisticResponse}
  `('$toggleName settings update', ({ optimisticResponse, toggleFinder, localErrorMock }) => {
    describe('success state', () => {
      it('emits a success event', async () => {
        mountComponent();

        fillApolloCache();
        toggleFinder().vm.$emit('change', false);

        await waitForPromises();

        expect(wrapper.emitted('success')).toEqual([[]]);
      });

      it('has an optimistic response', () => {
        mountComponent();

        fillApolloCache();

        expect(toggleFinder().props('value')).toBe(true);

        toggleFinder().vm.$emit('change', false);

        expect(optimisticResponse).toHaveBeenCalledWith(
          expect.objectContaining({
            enabled: false,
          }),
        );
      });
    });

    describe('errors', () => {
      it('mutation payload with root level errors', async () => {
        updateSettingsMutationResolver = jest.fn().mockResolvedValue(mutationErrorMock);
        updateTtlPoliciesMutationResolver = jest.fn().mockResolvedValue(mutationErrorMock);

        mountComponent();

        fillApolloCache();

        toggleFinder().vm.$emit('change', false);

        await waitForPromises();

        expect(wrapper.emitted('error')).toEqual([[]]);
      });

      it.each`
        type         | mutationResolverMock
        ${'local'}   | ${jest.fn().mockResolvedValue(localErrorMock({ errors: ['foo'] }))}
        ${'network'} | ${jest.fn().mockRejectedValue()}
      `('mutation payload with $type error', async ({ mutationResolverMock }) => {
        updateSettingsMutationResolver = mutationResolverMock;
        updateTtlPoliciesMutationResolver = mutationResolverMock;
        mountComponent();

        fillApolloCache();
        toggleFinder().vm.$emit('change', false);

        await waitForPromises();

        expect(wrapper.emitted('error')).toEqual([[]]);
      });
    });
  });

  describe('when isLoading is true', () => {
    beforeEach(() => {
      mountComponent({ isLoading: true });
    });

    it('disables enable proxy toggle', () => {
      expect(findEnableProxyToggle().props('disabled')).toBe(true);
    });

    it('hides the Docker Hub authentication section', () => {
      expect(findDockerHubAuthenticationSection().exists()).toBe(false);
    });

    it('disables enable ttl policies toggle', () => {
      expect(findEnableTtlPoliciesToggle().props('disabled')).toBe(true);
    });
  });
});
