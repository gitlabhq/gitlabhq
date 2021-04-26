import { GlSprintf, GlLink, GlAlert } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import component from '~/packages_and_registries/settings/group/components/group_settings_app.vue';
import MavenSettings from '~/packages_and_registries/settings/group/components/maven_settings.vue';
import {
  PACKAGE_SETTINGS_HEADER,
  PACKAGE_SETTINGS_DESCRIPTION,
  PACKAGES_DOCS_PATH,
  ERROR_UPDATING_SETTINGS,
  SUCCESS_UPDATING_SETTINGS,
} from '~/packages_and_registries/settings/group/constants';

import updateNamespacePackageSettings from '~/packages_and_registries/settings/group/graphql/mutations/update_group_packages_settings.mutation.graphql';
import getGroupPackagesSettingsQuery from '~/packages_and_registries/settings/group/graphql/queries/get_group_packages_settings.query.graphql';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import {
  groupPackageSettingsMock,
  groupPackageSettingsMutationMock,
  groupPackageSettingsMutationErrorMock,
} from '../mock_data';

jest.mock('~/flash');

const localVue = createLocalVue();

describe('Group Settings App', () => {
  let wrapper;
  let apolloProvider;
  let show;

  const defaultProvide = {
    defaultExpanded: false,
    groupPath: 'foo_group_path',
  };

  const mountComponent = ({
    provide = defaultProvide,
    resolver = jest.fn().mockResolvedValue(groupPackageSettingsMock),
    mutationResolver = jest.fn().mockResolvedValue(groupPackageSettingsMutationMock()),
    data = {},
  } = {}) => {
    localVue.use(VueApollo);

    const requestHandlers = [
      [getGroupPackagesSettingsQuery, resolver],
      [updateNamespacePackageSettings, mutationResolver],
    ];

    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMount(component, {
      localVue,
      apolloProvider,
      provide,
      data() {
        return {
          ...data,
        };
      },
      stubs: {
        GlSprintf,
        SettingsBlock,
      },
      mocks: {
        $toast: {
          show,
        },
      },
    });
  };

  beforeEach(() => {
    show = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findSettingsBlock = () => wrapper.find(SettingsBlock);
  const findDescription = () => wrapper.find('[data-testid="description"');
  const findLink = () => wrapper.find(GlLink);
  const findMavenSettings = () => wrapper.find(MavenSettings);
  const findAlert = () => wrapper.find(GlAlert);

  const waitForApolloQueryAndRender = async () => {
    await waitForPromises();
    await wrapper.vm.$nextTick();
  };

  const emitSettingsUpdate = (override) => {
    findMavenSettings().vm.$emit('update', {
      mavenDuplicateExceptionRegex: ')',
      ...override,
    });
  };

  it('renders a settings block', () => {
    mountComponent();

    expect(findSettingsBlock().exists()).toBe(true);
  });

  it('passes the correct props to settings block', () => {
    mountComponent();

    expect(findSettingsBlock().props('defaultExpanded')).toBe(false);
  });

  it('has the correct header text', () => {
    mountComponent();

    expect(wrapper.text()).toContain(PACKAGE_SETTINGS_HEADER);
  });

  it('has the correct description text', () => {
    mountComponent();

    expect(findDescription().text()).toMatchInterpolatedText(PACKAGE_SETTINGS_DESCRIPTION);
  });

  it('has the correct link', () => {
    mountComponent();

    expect(findLink().attributes()).toMatchObject({
      href: PACKAGES_DOCS_PATH,
      target: '_blank',
    });
    expect(findLink().text()).toBe('More Information');
  });

  it('calls the graphql API with the proper variables', () => {
    const resolver = jest.fn().mockResolvedValue(groupPackageSettingsMock);
    mountComponent({ resolver });

    expect(resolver).toHaveBeenCalledWith({
      fullPath: defaultProvide.groupPath,
    });
  });

  describe('maven settings', () => {
    it('exists', () => {
      mountComponent();

      expect(findMavenSettings().exists()).toBe(true);
    });

    it('assigns duplication allowness and exception props', async () => {
      mountComponent();

      expect(findMavenSettings().props('loading')).toBe(true);

      await waitForApolloQueryAndRender();

      const {
        mavenDuplicatesAllowed,
        mavenDuplicateExceptionRegex,
      } = groupPackageSettingsMock.data.group.packageSettings;

      expect(findMavenSettings().props()).toMatchObject({
        mavenDuplicatesAllowed,
        mavenDuplicateExceptionRegex,
        mavenDuplicateExceptionRegexError: '',
        loading: false,
      });
    });

    it('on update event calls the mutation', async () => {
      const mutationResolver = jest.fn().mockResolvedValue(groupPackageSettingsMutationMock());
      mountComponent({ mutationResolver });

      await waitForApolloQueryAndRender();

      emitSettingsUpdate();

      expect(mutationResolver).toHaveBeenCalledWith({
        input: { mavenDuplicateExceptionRegex: ')', namespacePath: 'foo_group_path' },
      });
    });
  });

  describe('settings update', () => {
    describe('success state', () => {
      it('shows a success alert', async () => {
        mountComponent();

        await waitForApolloQueryAndRender();

        emitSettingsUpdate();

        await waitForPromises();

        expect(show).toHaveBeenCalledWith(SUCCESS_UPDATING_SETTINGS, {
          type: 'success',
        });
      });

      it('has an optimistic response', async () => {
        const mavenDuplicateExceptionRegex = 'latest[main]something';
        mountComponent();

        await waitForApolloQueryAndRender();

        expect(findMavenSettings().props('mavenDuplicateExceptionRegex')).toBe('');

        emitSettingsUpdate({ mavenDuplicateExceptionRegex });

        // wait for apollo to update the model with the optimistic response
        await wrapper.vm.$nextTick();

        expect(findMavenSettings().props('mavenDuplicateExceptionRegex')).toBe(
          mavenDuplicateExceptionRegex,
        );

        // wait for the call to resolve
        await waitForPromises();

        expect(findMavenSettings().props('mavenDuplicateExceptionRegex')).toBe(
          mavenDuplicateExceptionRegex,
        );
      });
    });

    describe('errors', () => {
      const verifyAlert = () => {
        expect(findAlert().exists()).toBe(true);
        expect(findAlert().text()).toBe(ERROR_UPDATING_SETTINGS);
        expect(findAlert().props('variant')).toBe('warning');
      };

      it('mutation payload with root level errors', async () => {
        // note this is a complex test that covers all the path around errors that are shown in the form
        // it's one single it case, due to the expensive preparation and execution
        const mutationResolver = jest.fn().mockResolvedValue(groupPackageSettingsMutationErrorMock);
        mountComponent({ mutationResolver });

        await waitForApolloQueryAndRender();

        emitSettingsUpdate();

        await waitForApolloQueryAndRender();

        // errors are bound to the component
        expect(findMavenSettings().props('mavenDuplicateExceptionRegexError')).toBe(
          groupPackageSettingsMutationErrorMock.errors[0].extensions.problems[0].message,
        );

        // general error message is shown

        verifyAlert();

        emitSettingsUpdate();

        await wrapper.vm.$nextTick();

        // errors are reset on mutation call
        expect(findMavenSettings().props('mavenDuplicateExceptionRegexError')).toBe('');
      });

      it.each`
        type         | mutationResolver
        ${'local'}   | ${jest.fn().mockResolvedValue(groupPackageSettingsMutationMock({ errors: ['foo'] }))}
        ${'network'} | ${jest.fn().mockRejectedValue()}
      `('mutation payload with $type error', async ({ mutationResolver }) => {
        mountComponent({ mutationResolver });

        await waitForApolloQueryAndRender();

        emitSettingsUpdate();

        await waitForPromises();

        verifyAlert();
      });

      it('a successful request dismisses the alert', async () => {
        mountComponent({ data: { alertMessage: 'foo' } });

        await waitForApolloQueryAndRender();

        expect(findAlert().exists()).toBe(true);

        emitSettingsUpdate();

        await waitForPromises();

        expect(findAlert().exists()).toBe(false);
      });

      it('dismiss event from alert dismiss it from the page', async () => {
        mountComponent({ data: { alertMessage: 'foo' } });

        await waitForApolloQueryAndRender();

        expect(findAlert().exists()).toBe(true);

        findAlert().vm.$emit('dismiss');

        await wrapper.vm.$nextTick();

        expect(findAlert().exists()).toBe(false);
      });
    });
  });
});
