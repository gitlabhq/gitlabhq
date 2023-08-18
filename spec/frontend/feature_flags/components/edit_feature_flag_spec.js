import { GlToggle, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { mockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_HOST } from 'spec/test_constants';
import EditFeatureFlag from '~/feature_flags/components/edit_feature_flag.vue';
import Form from '~/feature_flags/components/form.vue';
import createStore from '~/feature_flags/store/edit';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

Vue.use(Vuex);

describe('Edit feature flag form', () => {
  let wrapper;
  let mock;

  const store = createStore({
    path: '/feature_flags',
    endpoint: `${TEST_HOST}/feature_flags.json`,
  });

  const factory = (provide = { searchPath: '/search' }) => {
    wrapper = shallowMount(EditFeatureFlag, {
      store,
      provide,
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(`${TEST_HOST}/feature_flags.json`).replyOnce(HTTP_STATUS_OK, {
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

    return waitForPromises();
  });

  afterEach(() => {
    mock.restore();
  });

  const findWarningGlAlert = () => wrapper.findComponent(GlAlert);

  it('should display the iid', () => {
    expect(wrapper.find('h3').text()).toContain('^5');
  });

  it('should render the toggle', () => {
    expect(wrapper.findComponent(GlToggle).exists()).toBe(true);
  });

  describe('with error', () => {
    it('should render the error', async () => {
      store.dispatch('receiveUpdateFeatureFlagError', { message: ['The name is required'] });
      await nextTick();
      const warningGlAlert = findWarningGlAlert();
      expect(warningGlAlert.exists()).toEqual(true);
      expect(warningGlAlert.text()).toContain('The name is required');
    });
  });

  describe('without error', () => {
    it('renders form title', () => {
      expect(wrapper.text()).toContain('^5 feature_flag');
    });

    it('should render feature flag form', () => {
      expect(wrapper.findComponent(Form).exists()).toEqual(true);
    });

    it('should track when the toggle is clicked', () => {
      const toggle = wrapper.findComponent(GlToggle);
      const spy = mockTracking('_category_', toggle.element, jest.spyOn);

      toggle.trigger('click');

      expect(spy).toHaveBeenCalledWith('_category_', 'click_button', {
        label: 'feature_flag_toggle',
      });
    });

    it('should render the toggle with a visually hidden label', () => {
      expect(wrapper.findComponent(GlToggle).props()).toMatchObject({
        label: 'Feature flag status',
        labelPosition: 'hidden',
      });
    });
  });
});
