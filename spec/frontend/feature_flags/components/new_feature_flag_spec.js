import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { TEST_HOST } from 'spec/test_constants';
import Form from '~/feature_flags/components/form.vue';
import NewFeatureFlag from '~/feature_flags/components/new_feature_flag.vue';
import createStore from '~/feature_flags/store/new';
import { allUsersStrategy } from '../mock_data';

const userCalloutId = 'feature_flags_new_version';
const userCalloutsPath = `${TEST_HOST}/user_callouts`;

Vue.use(Vuex);

describe('New feature flag form', () => {
  let wrapper;

  const store = createStore({
    endpoint: `${TEST_HOST}/feature_flags.json`,
    path: '/feature_flags',
  });

  const factory = (opts = {}) => {
    wrapper = shallowMount(NewFeatureFlag, {
      store,
      provide: {
        showUserCallout: true,
        userCalloutId,
        userCalloutsPath,
        environmentsEndpoint: 'environments.json',
        projectId: '8',
        ...opts,
      },
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

  it('renders form title', () => {
    expect(wrapper.text()).toContain('New feature flag');
  });

  it('should render feature flag form', () => {
    expect(wrapper.findComponent(Form).exists()).toEqual(true);
  });

  it('has an all users strategy by default', () => {
    const strategies = wrapper.findComponent(Form).props('strategies');

    expect(strategies).toEqual([allUsersStrategy]);
  });
});
