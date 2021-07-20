import { GlToggle, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
import Vuex from 'vuex';
import { mockTracking } from 'helpers/tracking_helper';
import { TEST_HOST } from 'spec/test_constants';
import EditFeatureFlag from '~/feature_flags/components/edit_feature_flag.vue';
import Form from '~/feature_flags/components/form.vue';
import createStore from '~/feature_flags/store/edit';
import axios from '~/lib/utils/axios_utils';

Vue.use(Vuex);
describe('Edit feature flag form', () => {
  let wrapper;
  let mock;

  const store = createStore({
    path: '/feature_flags',
    endpoint: `${TEST_HOST}/feature_flags.json`,
  });

  const factory = (provide = {}) => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
    wrapper = shallowMount(EditFeatureFlag, {
      store,
      provide,
    });
  };

  beforeEach((done) => {
    mock = new MockAdapter(axios);
    mock.onGet(`${TEST_HOST}/feature_flags.json`).replyOnce(200, {
      id: 21,
      iid: 5,
      active: true,
      created_at: '2019-01-17T17:27:39.778Z',
      updated_at: '2019-01-17T17:27:39.778Z',
      name: 'feature_flag',
      description: '',
      edit_path: '/h5bp/html5-boilerplate/-/feature_flags/21/edit',
      destroy_path: '/h5bp/html5-boilerplate/-/feature_flags/21',
    });
    factory();
    setImmediate(() => done());
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  const findWarningGlAlert = () => wrapper.findComponent(GlAlert);

  it('should display the iid', () => {
    expect(wrapper.find('h3').text()).toContain('^5');
  });

  it('should render the toggle', () => {
    expect(wrapper.find(GlToggle).exists()).toBe(true);
  });

  describe('with error', () => {
    it('should render the error', () => {
      store.dispatch('receiveUpdateFeatureFlagError', { message: ['The name is required'] });
      return wrapper.vm.$nextTick(() => {
        const warningGlAlert = findWarningGlAlert();
        expect(warningGlAlert.exists()).toEqual(true);
        expect(warningGlAlert.text()).toContain('The name is required');
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

    it('should track when the toggle is clicked', () => {
      const toggle = wrapper.find(GlToggle);
      const spy = mockTracking('_category_', toggle.element, jest.spyOn);

      toggle.trigger('click');

      expect(spy).toHaveBeenCalledWith('_category_', 'click_button', {
        label: 'feature_flag_toggle',
      });
    });

    it('should render the toggle with a visually hidden label', () => {
      expect(wrapper.find(GlToggle).props()).toMatchObject({
        label: 'Feature flag status',
        labelPosition: 'hidden',
      });
    });
  });
});
