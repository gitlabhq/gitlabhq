import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { GlToggle, GlAlert } from '@gitlab/ui';
import { TEST_HOST } from 'spec/test_constants';
import { mockTracking } from 'helpers/tracking_helper';
import { LEGACY_FLAG, NEW_VERSION_FLAG, NEW_FLAG_ALERT } from '~/feature_flags/constants';
import Form from '~/feature_flags/components/form.vue';
import createStore from '~/feature_flags/store/edit';
import EditFeatureFlag from '~/feature_flags/components/edit_feature_flag.vue';
import axios from '~/lib/utils/axios_utils';

const localVue = createLocalVue();
localVue.use(Vuex);

const userCalloutId = 'feature_flags_new_version';
const userCalloutsPath = `${TEST_HOST}/user_callouts`;

describe('Edit feature flag form', () => {
  let wrapper;
  let mock;

  const store = createStore({
    path: '/feature_flags',
    endpoint: `${TEST_HOST}/feature_flags.json`,
  });

  const factory = (opts = {}) => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
    wrapper = shallowMount(EditFeatureFlag, {
      localVue,
      store,
      provide: {
        showUserCallout: true,
        userCalloutId,
        userCalloutsPath,
        glFeatures: {
          featureFlagsNewVersion: true,
        },
        ...opts,
      },
    });
  };

  beforeEach(done => {
    mock = new MockAdapter(axios);
    mock.onGet(`${TEST_HOST}/feature_flags.json`).replyOnce(200, {
      id: 21,
      iid: 5,
      active: true,
      created_at: '2019-01-17T17:27:39.778Z',
      updated_at: '2019-01-17T17:27:39.778Z',
      name: 'feature_flag',
      description: '',
      version: LEGACY_FLAG,
      edit_path: '/h5bp/html5-boilerplate/-/feature_flags/21/edit',
      destroy_path: '/h5bp/html5-boilerplate/-/feature_flags/21',
      scopes: [
        {
          id: 21,
          active: false,
          environment_scope: '*',
          created_at: '2019-01-17T17:27:39.778Z',
          updated_at: '2019-01-17T17:27:39.778Z',
        },
      ],
    });
    factory();
    setImmediate(() => done());
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  const findAlert = () => wrapper.find(GlAlert);

  it('should display the iid', () => {
    expect(wrapper.find('h3').text()).toContain('^5');
  });

  it('should render the toggle', () => {
    expect(wrapper.find(GlToggle).exists()).toBe(true);
  });

  it('should set the value of the toggle to whether or not the flag is active', () => {
    expect(wrapper.find(GlToggle).props('value')).toBe(true);
  });

  it('should not alert users that feature flags are changing soon', () => {
    expect(findAlert().text()).toContain('GitLab is moving to a new way of managing feature flags');
  });

  describe('with error', () => {
    it('should render the error', () => {
      store.dispatch('receiveUpdateFeatureFlagError', { message: ['The name is required'] });
      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find('.alert-danger').exists()).toEqual(true);
        expect(wrapper.find('.alert-danger').text()).toContain('The name is required');
      });
    });
  });

  describe('without error', () => {
    it('renders form title', () => {
      expect(wrapper.text()).toContain('^5 feature_flag');
    });

    it('should render feature flag form', () => {
      expect(wrapper.find(Form).exists()).toEqual(true);
    });

    it('should set the version of the form from the feature flag', () => {
      expect(wrapper.find(Form).props('version')).toBe(LEGACY_FLAG);

      mock.resetHandlers();

      mock.onGet(`${TEST_HOST}/feature_flags.json`).replyOnce(200, {
        id: 21,
        iid: 5,
        active: true,
        created_at: '2019-01-17T17:27:39.778Z',
        updated_at: '2019-01-17T17:27:39.778Z',
        name: 'feature_flag',
        description: '',
        version: NEW_VERSION_FLAG,
        edit_path: '/h5bp/html5-boilerplate/-/feature_flags/21/edit',
        destroy_path: '/h5bp/html5-boilerplate/-/feature_flags/21',
        strategies: [],
      });

      factory();

      return axios.waitForAll().then(() => {
        expect(wrapper.find(Form).props('version')).toBe(NEW_VERSION_FLAG);
      });
    });

    it('should track when the toggle is clicked', () => {
      const toggle = wrapper.find(GlToggle);
      const spy = mockTracking('_category_', toggle.element, jest.spyOn);

      toggle.trigger('click');

      expect(spy).toHaveBeenCalledWith('_category_', 'click_button', {
        label: 'feature_flag_toggle',
      });
    });
  });

  describe('without new version flags', () => {
    beforeEach(() => factory({ glFeatures: { featureFlagsNewVersion: false } }));

    it('should alert users that feature flags are changing soon', () => {
      expect(findAlert().text()).toBe(NEW_FLAG_ALERT);
    });
  });

  describe('dismissing new version alert', () => {
    beforeEach(() => {
      factory({ glFeatures: { featureFlagsNewVersion: false } });
      mock.onPost(userCalloutsPath, { feature_name: userCalloutId }).reply(200);
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
