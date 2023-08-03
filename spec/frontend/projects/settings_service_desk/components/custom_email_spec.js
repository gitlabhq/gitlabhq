import { nextTick } from 'vue';
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { HTTP_STATUS_OK, HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import CustomEmail from '~/projects/settings_service_desk/components/custom_email.vue';
import {
  FEEDBACK_ISSUE_URL,
  I18N_GENERIC_ERROR,
} from '~/projects/settings_service_desk/custom_email_constants';
import { MOCK_CUSTOM_EMAIL_EMPTY } from './mock_data';

describe('CustomEmail', () => {
  let axiosMock;
  let wrapper;

  const defaultProps = {
    incomingEmail: 'incoming@example.com',
    customEmailEndpoint: '/flightjs/Flight/-/service_desk/custom_email',
  };

  const createWrapper = (props = {}) => {
    wrapper = extendedWrapper(
      mount(CustomEmail, {
        propsData: { ...defaultProps, ...props },
      }),
    );
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findFeedbackLink = () => wrapper.findByTestId('feedback-link');

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  it('displays link to feedback issue', () => {
    createWrapper();

    expect(findFeedbackLink().attributes('href')).toEqual(FEEDBACK_ISSUE_URL);
  });

  describe('when initial resource loading returns no configured custom email', () => {
    beforeEach(() => {
      axiosMock
        .onGet(defaultProps.customEmailEndpoint)
        .reply(HTTP_STATUS_OK, MOCK_CUSTOM_EMAIL_EMPTY);

      createWrapper();
    });

    it('displays loading icon while fetching data', async () => {
      // while loading
      expect(findLoadingIcon().exists()).toBe(true);
      await waitForPromises();
      // loading completed
      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('when initial resource loading returns 404', () => {
    beforeEach(async () => {
      axiosMock.onGet(defaultProps.customEmailEndpoint).reply(HTTP_STATUS_NOT_FOUND);

      createWrapper();
      await waitForPromises();
    });

    it('displays error alert with correct text', () => {
      expect(findLoadingIcon().exists()).toBe(false);

      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toBe(I18N_GENERIC_ERROR);
    });

    it('dismissing the alert removes it', async () => {
      expect(findAlert().exists()).toBe(true);

      findAlert().vm.$emit('dismiss');

      await nextTick();

      expect(findAlert().exists()).toBe(false);
    });
  });
});
