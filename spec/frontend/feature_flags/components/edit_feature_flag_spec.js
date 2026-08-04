import { GlToggle, GlAlert, GlSprintf } from '@gitlab/ui';
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
import DetailLayout from '~/vue_shared/components/detail_layout.vue';
import BaseLayout from '~/vue_shared/components/base_layout.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

Vue.use(Vuex);

describe('Edit feature flag form', () => {
  let wrapper;
  let mock;
  let store;

  const factory = (provide = { searchPath: '/search' }) => {
    store = createStore({
      path: '/feature_flags',
      endpoint: `${TEST_HOST}/feature_flags.json`,
    });
    wrapper = shallowMount(EditFeatureFlag, {
      store,
      provide,
      stubs: { DetailLayout, BaseLayout, PageHeading, GlSprintf },
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
  const findAlertsWrapper = () => wrapper.find('[data-testid="base-layout-alerts"]');

  it('should display the title without the iid, with a monospace name', () => {
    const heading = wrapper.find('h1');
    expect(heading.text()).toMatchInterpolatedText('Feature flag feature_flag');
  });

  it('should display the labeled ID reference in the heading description, with a bold label', () => {
    const description = wrapper.find('[data-testid="page-heading-description"]');
    expect(description.text()).toMatchInterpolatedText('ID: ^5');
  });

  it('should render the toggle', () => {
    expect(wrapper.findComponent(GlToggle).exists()).toBe(true);
  });

  describe('with error', () => {
    it('should render the error', async () => {
      store.dispatch('receiveUpdateFeatureFlagError', { message: ['The name is required'] });
      await nextTick();
      const warningGlAlert = findWarningGlAlert();
      expect(findAlertsWrapper().exists()).toBe(true);
      expect(warningGlAlert.exists()).toEqual(true);
      expect(warningGlAlert.text()).toContain('The name is required');
    });
  });

  describe('without error', () => {
    it('does not render the alerts wrapper', () => {
      expect(findAlertsWrapper().exists()).toBe(false);
    });

    it('renders form title', () => {
      expect(wrapper.text()).toContain('Feature flag feature_flag');
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

    it('should render the toggle with the Status label', () => {
      expect(wrapper.findComponent(GlToggle).props()).toMatchObject({
        label: 'Status',
      });
    });
  });
});
