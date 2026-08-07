import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { TEST_HOST } from 'spec/test_constants';
import Form from '~/feature_flags/components/form.vue';
import NewFeatureFlag from '~/feature_flags/components/new_feature_flag.vue';
import createStore from '~/feature_flags/store/new';
import DetailLayout from '~/vue_shared/components/detail_layout.vue';
import BaseLayout from '~/vue_shared/components/base_layout.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import { allUsersStrategy } from '../mock_data';

Vue.use(Vuex);

describe('New feature flag form', () => {
  let wrapper;
  let store;

  const factory = (opts = {}) => {
    store = createStore({
      endpoint: `${TEST_HOST}/feature_flags.json`,
      path: '/feature_flags',
    });
    wrapper = shallowMount(NewFeatureFlag, {
      store,
      provide: {
        environmentsEndpoint: 'environments.json',
        projectId: '8',
        ...opts,
      },
      stubs: { DetailLayout, BaseLayout, PageHeading },
    });
  };

  const findWarningGlAlert = () =>
    wrapper.findAllComponents(GlAlert).filter((c) => c.props('variant') === 'warning');

  beforeEach(() => {
    factory();
  });

  describe('with error', () => {
    it('should render the error', async () => {
      store.dispatch('receiveCreateFeatureFlagError', { message: ['The name is required'] });
      await nextTick();
      const warningGlAlert = findWarningGlAlert();
      expect(warningGlAlert.at(0).exists()).toBe(true);
      expect(warningGlAlert.at(0).text()).toContain('The name is required');
    });
  });

  describe('without error', () => {
    it('should not render an alert', () => {
      expect(findWarningGlAlert()).toHaveLength(0);
    });
  });

  it('renders the page title', () => {
    expect(wrapper.find('h1').text()).toBe('New feature flag');
  });

  it('should render feature flag form', () => {
    expect(wrapper.findComponent(Form).exists()).toEqual(true);
  });

  it('has an all users strategy by default', () => {
    const strategies = wrapper.findComponent(Form).props('strategies');

    expect(strategies).toEqual([allUsersStrategy]);
  });
});
