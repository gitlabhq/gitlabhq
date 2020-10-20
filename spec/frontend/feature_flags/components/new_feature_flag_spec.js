import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import MockAdapter from 'axios-mock-adapter';
import { GlAlert } from '@gitlab/ui';
import { TEST_HOST } from 'spec/test_constants';
import Form from '~/feature_flags/components/form.vue';
import createStore from '~/feature_flags/store/new';
import NewFeatureFlag from '~/feature_flags/components/new_feature_flag.vue';
import {
  ROLLOUT_STRATEGY_ALL_USERS,
  DEFAULT_PERCENT_ROLLOUT,
  NEW_FLAG_ALERT,
} from '~/feature_flags/constants';
import axios from '~/lib/utils/axios_utils';
import { allUsersStrategy } from '../mock_data';

const userCalloutId = 'feature_flags_new_version';
const userCalloutsPath = `${TEST_HOST}/user_callouts`;

const localVue = createLocalVue();
localVue.use(Vuex);

describe('New feature flag form', () => {
  let wrapper;

  const store = createStore({
    endpoint: `${TEST_HOST}/feature_flags.json`,
    path: '/feature_flags',
  });

  const factory = (opts = {}) => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
    wrapper = shallowMount(NewFeatureFlag, {
      localVue,
      store,
      provide: {
        showUserCallout: true,
        userCalloutId,
        userCalloutsPath,
        environmentsEndpoint: 'environments.json',
        projectId: '8',
        glFeatures: {
          featureFlagsNewVersion: true,
        },
        ...opts,
      },
    });
  };

  beforeEach(() => {
    factory();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findAlert = () => wrapper.find(GlAlert);

  describe('with error', () => {
    it('should render the error', () => {
      store.dispatch('receiveCreateFeatureFlagError', { message: ['The name is required'] });
      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find('.alert').exists()).toEqual(true);
        expect(wrapper.find('.alert').text()).toContain('The name is required');
      });
    });
  });

  it('renders form title', () => {
    expect(wrapper.find('h3').text()).toEqual('New feature flag');
  });

  it('should render feature flag form', () => {
    expect(wrapper.find(Form).exists()).toEqual(true);
  });

  it('should render default * row', () => {
    const defaultScope = {
      id: expect.any(String),
      environmentScope: '*',
      active: true,
      rolloutStrategy: ROLLOUT_STRATEGY_ALL_USERS,
      rolloutPercentage: DEFAULT_PERCENT_ROLLOUT,
      rolloutUserIds: '',
    };
    expect(wrapper.vm.scopes).toEqual([defaultScope]);

    expect(wrapper.find(Form).props('scopes')).toContainEqual(defaultScope);
  });

  it('should not alert users that feature flags are changing soon', () => {
    expect(wrapper.find(GlAlert).exists()).toBe(false);
  });

  it('has an all users strategy by default', () => {
    const strategies = wrapper.find(Form).props('strategies');

    expect(strategies).toEqual([allUsersStrategy]);
  });

  describe('without new version flags', () => {
    beforeEach(() => factory({ glFeatures: { featureFlagsNewVersion: false } }));

    it('should alert users that feature flags are changing soon', () => {
      expect(findAlert().text()).toBe(NEW_FLAG_ALERT);
    });
  });

  describe('dismissing new version alert', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
      mock.onPost(userCalloutsPath, { feature_name: userCalloutId }).reply(200);
      factory({ glFeatures: { featureFlagsNewVersion: false } });
      findAlert().vm.$emit('dismiss');
      return wrapper.vm.$nextTick();
    });

    afterEach(() => {
      mock.restore();
    });

    it('should hide the alert', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('should send the dismissal event', () => {
      expect(mock.history.post.length).toBe(1);
    });
  });
});
