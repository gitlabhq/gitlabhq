import { GlLoadingIcon } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import ImportErrorDetails from '~/pages/import/history/components/import_error_details.vue';

describe('ImportErrorDetails', () => {
  const FAKE_ID = 5;
  const API_URL = `/api/v4/projects/${FAKE_ID}`;

  let wrapper;
  let mock;

  function createComponent({ shallow = true } = {}) {
    const mountFn = shallow ? shallowMount : mount;
    wrapper = mountFn(ImportErrorDetails, {
      propsData: {
        id: FAKE_ID,
      },
    });
  }

  beforeEach(() => {
    gon.api_version = 'v4';
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('general behavior', () => {
    it('renders loading state when loading', () => {
      createComponent();
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    it('renders import_error if it is available', async () => {
      const FAKE_IMPORT_ERROR = 'IMPORT ERROR';
      mock.onGet(API_URL).reply(HTTP_STATUS_OK, { import_error: FAKE_IMPORT_ERROR });
      createComponent();
      await axios.waitForAll();

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
      expect(wrapper.find('pre').text()).toBe(FAKE_IMPORT_ERROR);
    });

    it('renders default text if error is not available', async () => {
      mock.onGet(API_URL).reply(HTTP_STATUS_OK, { import_error: null });
      createComponent();
      await axios.waitForAll();

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
      expect(wrapper.find('pre').text()).toBe('No additional information provided.');
    });
  });
});
