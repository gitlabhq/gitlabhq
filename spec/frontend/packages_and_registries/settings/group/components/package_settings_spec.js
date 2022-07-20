import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import DuplicatesSettings from '~/packages_and_registries/settings/group/components/duplicates_settings.vue';
import GenericSettings from '~/packages_and_registries/settings/group/components/generic_settings.vue';
import component from '~/packages_and_registries/settings/group/components/packages_settings.vue';
import MavenSettings from '~/packages_and_registries/settings/group/components/maven_settings.vue';
import {
  PACKAGE_SETTINGS_HEADER,
  PACKAGE_SETTINGS_DESCRIPTION,
} from '~/packages_and_registries/settings/group/constants';

import updateNamespacePackageSettings from '~/packages_and_registries/settings/group/graphql/mutations/update_group_packages_settings.mutation.graphql';
import getGroupPackagesSettingsQuery from '~/packages_and_registries/settings/group/graphql/queries/get_group_packages_settings.query.graphql';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import { updateGroupPackagesSettingsOptimisticResponse } from '~/packages_and_registries/settings/group/graphql/utils/optimistic_responses';
import {
  packageSettings,
  groupPackageSettingsMock,
  groupPackageSettingsMutationMock,
  groupPackageSettingsMutationErrorMock,
} from '../mock_data';

jest.mock('~/flash');
jest.mock('~/packages_and_registries/settings/group/graphql/utils/optimistic_responses');

describe('Packages Settings', () => {
  let wrapper;
  let apolloProvider;

  const defaultProvide = {
    groupPath: 'foo_group_path',
  };

  const mountComponent = ({
    mutationResolver = jest.fn().mockResolvedValue(groupPackageSettingsMutationMock()),
  } = {}) => {
    Vue.use(VueApollo);

    const requestHandlers = [[updateNamespacePackageSettings, mutationResolver]];

    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(component, {
      apolloProvider,
      provide: defaultProvide,
      propsData: {
        packageSettings: packageSettings(),
      },
      stubs: {
        SettingsBlock,
        MavenSettings,
        GenericSettings,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findSettingsBlock = () => wrapper.findComponent(SettingsBlock);
  const findDescription = () => wrapper.findByTestId('description');
  const findMavenSettings = () => wrapper.findComponent(MavenSettings);
  const findMavenDuplicatedSettings = () => findMavenSettings().findComponent(DuplicatesSettings);
  const findGenericSettings = () => wrapper.findComponent(GenericSettings);
  const findGenericDuplicatedSettings = () =>
    findGenericSettings().findComponent(DuplicatesSettings);

  const fillApolloCache = () => {
    apolloProvider.defaultClient.cache.writeQuery({
      query: getGroupPackagesSettingsQuery,
      variables: {
        fullPath: defaultProvide.groupPath,
      },
      ...groupPackageSettingsMock,
    });
  };

  const emitMavenSettingsUpdate = (override) => {
    findMavenDuplicatedSettings().vm.$emit('update', {
      mavenDuplicateExceptionRegex: ')',
      ...override,
    });
  };

  it('renders a settings block', () => {
    mountComponent();

    expect(findSettingsBlock().exists()).toBe(true);
  });

  it('has the correct header text', () => {
    mountComponent();

    expect(wrapper.text()).toContain(PACKAGE_SETTINGS_HEADER);
  });

  it('has the correct description text', () => {
    mountComponent();

    expect(findDescription().text()).toMatchInterpolatedText(PACKAGE_SETTINGS_DESCRIPTION);
  });

  describe('maven settings', () => {
    it('exists', () => {
      mountComponent();

      expect(findMavenSettings().exists()).toBe(true);
    });

    it('assigns duplication allowness and exception props', async () => {
      mountComponent();

      const { mavenDuplicatesAllowed, mavenDuplicateExceptionRegex } = packageSettings();

      expect(findMavenDuplicatedSettings().props()).toMatchObject({
        duplicatesAllowed: mavenDuplicatesAllowed,
        duplicateExceptionRegex: mavenDuplicateExceptionRegex,
        duplicateExceptionRegexError: '',
        loading: false,
      });
    });

    it('on update event calls the mutation', () => {
      const mutationResolver = jest.fn().mockResolvedValue(groupPackageSettingsMutationMock());
      mountComponent({ mutationResolver });

      fillApolloCache();

      emitMavenSettingsUpdate();

      expect(mutationResolver).toHaveBeenCalledWith({
        input: { mavenDuplicateExceptionRegex: ')', namespacePath: 'foo_group_path' },
      });
    });
  });

  describe('generic settings', () => {
    it('exists', () => {
      mountComponent();

      expect(findGenericSettings().exists()).toBe(true);
    });

    it('assigns duplication allowness and exception props', async () => {
      mountComponent();

      const { genericDuplicatesAllowed, genericDuplicateExceptionRegex } = packageSettings();

      expect(findGenericDuplicatedSettings().props()).toMatchObject({
        duplicatesAllowed: genericDuplicatesAllowed,
        duplicateExceptionRegex: genericDuplicateExceptionRegex,
        duplicateExceptionRegexError: '',
        loading: false,
      });
    });

    it('on update event calls the mutation', async () => {
      const mutationResolver = jest.fn().mockResolvedValue(groupPackageSettingsMutationMock());
      mountComponent({ mutationResolver });

      fillApolloCache();

      findMavenDuplicatedSettings().vm.$emit('update', {
        genericDuplicateExceptionRegex: ')',
      });

      expect(mutationResolver).toHaveBeenCalledWith({
        input: { genericDuplicateExceptionRegex: ')', namespacePath: 'foo_group_path' },
      });
    });
  });

  describe('settings update', () => {
    describe('success state', () => {
      it('emits a success event', async () => {
        mountComponent();

        fillApolloCache();
        emitMavenSettingsUpdate();

        await waitForPromises();

        expect(wrapper.emitted('success')).toEqual([[]]);
      });

      it('has an optimistic response', () => {
        const mavenDuplicateExceptionRegex = 'latest[main]something';
        mountComponent();

        fillApolloCache();

        expect(findMavenDuplicatedSettings().props('duplicateExceptionRegex')).toBe('');

        emitMavenSettingsUpdate({ mavenDuplicateExceptionRegex });

        expect(updateGroupPackagesSettingsOptimisticResponse).toHaveBeenCalledWith({
          ...packageSettings(),
          mavenDuplicateExceptionRegex,
        });
      });
    });

    describe('errors', () => {
      it('mutation payload with root level errors', async () => {
        // note this is a complex test that covers all the path around errors that are shown in the form
        // it's one single it case, due to the expensive preparation and execution
        const mutationResolver = jest.fn().mockResolvedValue(groupPackageSettingsMutationErrorMock);
        mountComponent({ mutationResolver });

        fillApolloCache();

        emitMavenSettingsUpdate();

        await waitForPromises();

        // errors are bound to the component
        expect(findMavenDuplicatedSettings().props('duplicateExceptionRegexError')).toBe(
          groupPackageSettingsMutationErrorMock.errors[0].extensions.problems[0].message,
        );

        // general error message is shown

        expect(wrapper.emitted('error')).toEqual([[]]);

        emitMavenSettingsUpdate();

        await nextTick();

        // errors are reset on mutation call
        expect(findMavenDuplicatedSettings().props('duplicateExceptionRegexError')).toBe('');
      });

      it.each`
        type         | mutationResolver
        ${'local'}   | ${jest.fn().mockResolvedValue(groupPackageSettingsMutationMock({ errors: ['foo'] }))}
        ${'network'} | ${jest.fn().mockRejectedValue()}
      `('mutation payload with $type error', async ({ mutationResolver }) => {
        mountComponent({ mutationResolver });

        fillApolloCache();
        emitMavenSettingsUpdate();

        await waitForPromises();

        expect(wrapper.emitted('error')).toEqual([[]]);
      });
    });
  });
});
