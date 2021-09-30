import { GlAlert } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import { nextTick } from 'vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PackagesSettings from '~/packages_and_registries/settings/group/components/packages_settings.vue';

import component from '~/packages_and_registries/settings/group/components/group_settings_app.vue';

import {
  ERROR_UPDATING_SETTINGS,
  SUCCESS_UPDATING_SETTINGS,
} from '~/packages_and_registries/settings/group/constants';

import getGroupPackagesSettingsQuery from '~/packages_and_registries/settings/group/graphql/queries/get_group_packages_settings.query.graphql';
import { groupPackageSettingsMock, packageSettings } from '../mock_data';

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
    resolver = jest.fn().mockResolvedValue(groupPackageSettingsMock),
  } = {}) => {
    localVue.use(VueApollo);

    const requestHandlers = [[getGroupPackagesSettingsQuery, resolver]];

    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMount(component, {
      localVue,
      apolloProvider,
      provide: defaultProvide,
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
  });

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findPackageSettings = () => wrapper.findComponent(PackagesSettings);

  const waitForApolloQueryAndRender = async () => {
    await waitForPromises();
    await nextTick();
  };

  describe.each`
    finder                 | entityProp           | entityValue
    ${findPackageSettings} | ${'packageSettings'} | ${packageSettings()}
  `('settings blocks', ({ finder, entityProp, entityValue }) => {
    beforeEach(() => {
      mountComponent();
      return waitForApolloQueryAndRender();
    });

    it('renders the settings block', () => {
      expect(finder().exists()).toBe(true);
    });

    it('binds the correctProps', () => {
      expect(finder().props()).toMatchObject({
        isLoading: false,
        [entityProp]: entityValue,
      });
    });

    describe('success event', () => {
      it('shows a success toast', () => {
        finder().vm.$emit('success');
        expect(show).toHaveBeenCalledWith(SUCCESS_UPDATING_SETTINGS);
      });

      it('hides the error alert', async () => {
        finder().vm.$emit('error');
        await nextTick();

        expect(findAlert().exists()).toBe(true);

        finder().vm.$emit('success');
        await nextTick();

        expect(findAlert().exists()).toBe(false);
      });
    });

    describe('error event', () => {
      beforeEach(() => {
        finder().vm.$emit('error');
        return nextTick();
      });

      it('shows an alert', () => {
        expect(findAlert().exists()).toBe(true);
      });

      it('alert has the right text', () => {
        expect(findAlert().text()).toBe(ERROR_UPDATING_SETTINGS);
      });

      it('dismissing the alert removes it', async () => {
        expect(findAlert().exists()).toBe(true);

        findAlert().vm.$emit('dismiss');

        await nextTick();

        expect(findAlert().exists()).toBe(false);
      });
    });
  });
});
