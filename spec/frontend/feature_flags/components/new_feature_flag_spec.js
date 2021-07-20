import { GlAlert } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { TEST_HOST } from 'spec/test_constants';
import Form from '~/feature_flags/components/form.vue';
import NewFeatureFlag from '~/feature_flags/components/new_feature_flag.vue';
import createStore from '~/feature_flags/store/new';
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
        ...opts,
      },
    });
  };

  const findWarningGlAlert = () =>
    wrapper.findAll(GlAlert).filter((c) => c.props('variant') === 'warning');

  beforeEach(() => {
    factory();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with error', () => {
    it('should render the error', () => {
      store.dispatch('receiveCreateFeatureFlagError', { message: ['The name is required'] });
      return wrapper.vm.$nextTick(() => {
        const warningGlAlert = findWarningGlAlert();
        expect(warningGlAlert.at(0).exists()).toBe(true);
        expect(warningGlAlert.at(0).text()).toContain('The name is required');
      });
    });
  });

  it('renders form title', () => {
    expect(wrapper.find('h3').text()).toEqual('New feature flag');
  });

  it('should render feature flag form', () => {
    expect(wrapper.find(Form).exists()).toEqual(true);
  });

  it('has an all users strategy by default', () => {
    const strategies = wrapper.find(Form).props('strategies');

    expect(strategies).toEqual([allUsersStrategy]);
  });
});
