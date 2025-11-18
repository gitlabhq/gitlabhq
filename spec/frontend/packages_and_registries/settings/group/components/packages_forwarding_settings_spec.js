import Vue from 'vue';
import { GlButton, GlLink, GlSprintf } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import component from '~/packages_and_registries/settings/group/components/packages_forwarding_settings.vue';
import {
  REQUEST_FORWARDING_HELP_PAGE_PATH,
  PACKAGE_FORWARDING_SETTINGS_HEADER,
} from '~/packages_and_registries/settings/group/constants';

import updateNamespacePackageSettings from '~/packages_and_registries/settings/group/graphql/mutations/update_group_packages_settings.mutation.graphql';
import getGroupPackagesSettingsQuery from '~/packages_and_registries/settings/group/graphql/queries/get_group_packages_settings.query.graphql';
import SettingsSection from '~/vue_shared/components/settings/settings_section.vue';
import { updateGroupPackagesSettingsOptimisticResponse } from '~/packages_and_registries/settings/group/graphql/utils/optimistic_responses';
import {
  packageSettings,
  packageForwardingSettings,
  groupPackageSettingsMock,
  groupPackageForwardSettingsMutationMock,
  mutationErrorMock,
  npmProps,
  pypiProps,
  mavenProps,
} from '../mock_data';

jest.mock('~/alert');
jest.mock('~/packages_and_registries/settings/group/graphql/utils/optimistic_responses');

describe('Packages Forwarding Settings', () => {
  let wrapper;
  let apolloProvider;
  const mutationResolverFn = jest.fn().mockResolvedValue(groupPackageForwardSettingsMutationMock());

  const defaultProvide = {
    groupPath: 'foo_group_path',
  };

  const mountComponent = ({
    forwardSettings = { ...packageSettings },
    features = {},
    mutationResolver = mutationResolverFn,
  } = {}) => {
    Vue.use(VueApollo);

    const requestHandlers = [[updateNamespacePackageSettings, mutationResolver]];

    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(component, {
      apolloProvider,
      provide: {
        ...defaultProvide,
        glFeatures: {
          ...features,
        },
      },
      propsData: {
        forwardSettings,
      },
      stubs: {
        GlSprintf,
        SettingsSection,
      },
    });
  };

  const findSettingsBlock = () => wrapper.findComponent(SettingsSection);
  const findForm = () => wrapper.find('form');
  const findSubmitButton = () => findForm().findComponent(GlButton);
  const findDescription = () => wrapper.findByTestId('description');
  const findMavenForwardingSettings = () => wrapper.findByTestId('maven');
  const findNpmForwardingSettings = () => wrapper.findByTestId('npm');
  const findPyPiForwardingSettings = () => wrapper.findByTestId('pypi');
  const findRequestForwardingDocsLink = () => wrapper.findComponent(GlLink);

  const fillApolloCache = () => {
    apolloProvider.defaultClient.cache.writeQuery({
      query: getGroupPackagesSettingsQuery,
      variables: {
        fullPath: defaultProvide.groupPath,
      },
      ...groupPackageSettingsMock,
    });
  };

  const updateNpmSettings = () => {
    findNpmForwardingSettings().vm.$emit('update', 'npmPackageRequestsForwarding', false);
  };

  const submitForm = () => {
    findForm().trigger('submit');
    return waitForPromises();
  };

  afterEach(() => {
    apolloProvider = null;
  });

  it('renders a settings block', () => {
    mountComponent();

    expect(findSettingsBlock().exists()).toBe(true);
  });

  it('has the correct header text', () => {
    mountComponent();

    expect(wrapper.text()).toContain(PACKAGE_FORWARDING_SETTINGS_HEADER);
  });

  it('has the correct description text', () => {
    mountComponent();

    expect(findDescription().text()).toBe(
      'Forward package requests to a public registry if the packages are not found in the GitLab package registry.',
    );
  });

  it('has the right help link', () => {
    mountComponent();

    expect(findRequestForwardingDocsLink().attributes('href')).toBe(
      REQUEST_FORWARDING_HELP_PAGE_PATH,
    );
  });

  it('watches changes to props', async () => {
    mountComponent();

    expect(findNpmForwardingSettings().props()).toMatchObject(npmProps);

    await wrapper.setProps({
      forwardSettings: {
        ...packageSettings,
        npmPackageRequestsForwardingLocked: true,
      },
    });

    expect(findNpmForwardingSettings().props()).toMatchObject({ ...npmProps, disabled: true });
  });

  it('submit button is disabled', () => {
    mountComponent();

    expect(findSubmitButton().props('disabled')).toBe(true);
  });

  describe.each`
    type       | finder                         | props         | field
    ${'npm'}   | ${findNpmForwardingSettings}   | ${npmProps}   | ${'npmPackageRequestsForwarding'}
    ${'pypi'}  | ${findPyPiForwardingSettings}  | ${pypiProps}  | ${'pypiPackageRequestsForwarding'}
    ${'maven'} | ${findMavenForwardingSettings} | ${mavenProps} | ${'mavenPackageRequestsForwarding'}
  `('$type settings', ({ finder, props, field }) => {
    beforeEach(() => {
      mountComponent({ features: { mavenCentralRequestForwarding: true } });
    });

    it('assigns forwarding settings props', () => {
      expect(finder().props()).toMatchObject(props);
    });

    it('on update event enables submit button', async () => {
      finder().vm.$emit('update', field, false);

      await waitForPromises();

      expect(findSubmitButton().props('disabled')).toBe(false);
    });
  });

  describe('maven settings', () => {
    describe('with feature turned off', () => {
      it('does not exist', () => {
        mountComponent();

        expect(findMavenForwardingSettings().exists()).toBe(false);
      });
    });
  });

  describe('settings update', () => {
    describe('success state', () => {
      it('calls the mutation with the right variables', async () => {
        const {
          mavenPackageRequestsForwardingLocked,
          npmPackageRequestsForwardingLocked,
          pypiPackageRequestsForwardingLocked,
          ...packageSettingsInput
        } = packageForwardingSettings;

        mountComponent();

        fillApolloCache();
        updateNpmSettings();

        await submitForm();

        expect(mutationResolverFn).toHaveBeenCalledWith({
          input: {
            namespacePath: defaultProvide.groupPath,
            ...packageSettingsInput,
            npmPackageRequestsForwarding: false,
          },
        });
      });

      it('when field are locked calls the mutation with the right variables', async () => {
        mountComponent({
          forwardSettings: {
            ...packageSettings,
            mavenPackageRequestsForwardingLocked: true,
            pypiPackageRequestsForwardingLocked: true,
          },
        });

        fillApolloCache();
        updateNpmSettings();

        await submitForm();

        expect(mutationResolverFn).toHaveBeenCalledWith({
          input: {
            namespacePath: defaultProvide.groupPath,
            lockNpmPackageRequestsForwarding: false,
            npmPackageRequestsForwarding: false,
          },
        });
      });

      it('emits a success event', async () => {
        mountComponent();
        fillApolloCache();
        updateNpmSettings();

        await submitForm();

        expect(wrapper.emitted('success')).toHaveLength(1);
      });

      it('has an optimistic response', async () => {
        const npmPackageRequestsForwarding = false;
        mountComponent();

        fillApolloCache();

        expect(findNpmForwardingSettings().props('forwarding')).toBe(true);

        updateNpmSettings();
        await submitForm();

        expect(updateGroupPackagesSettingsOptimisticResponse).toHaveBeenCalledWith({
          ...packageSettings,
          npmPackageRequestsForwarding,
        });
        expect(findNpmForwardingSettings().props('forwarding')).toBe(npmPackageRequestsForwarding);
      });
    });

    describe('errors', () => {
      it('mutation payload with root level errors', async () => {
        const mutationResolver = jest.fn().mockResolvedValue(mutationErrorMock);
        mountComponent({ mutationResolver });

        fillApolloCache();

        updateNpmSettings();
        await submitForm();

        expect(wrapper.emitted('error')).toHaveLength(1);
      });

      it.each`
        type         | mutationResolver
        ${'local'}   | ${jest.fn().mockResolvedValue(groupPackageForwardSettingsMutationMock({ errors: ['foo'] }))}
        ${'network'} | ${jest.fn().mockRejectedValue()}
      `('mutation payload with $type error', async ({ mutationResolver }) => {
        mountComponent({ mutationResolver });

        fillApolloCache();

        updateNpmSettings();
        await submitForm();

        expect(wrapper.emitted('error')).toHaveLength(1);
      });
    });
  });
});
