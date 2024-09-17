import { nextTick } from 'vue';
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';
import { HTTP_STATUS_OK, HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import CustomEmailWrapper from '~/projects/settings_service_desk/components/custom_email_wrapper.vue';
import CustomEmailForm from '~/projects/settings_service_desk/components/custom_email_form.vue';
import CustomEmail from '~/projects/settings_service_desk/components/custom_email.vue';
import CustomEmailConfirmModal from '~/projects/settings_service_desk/components/custom_email_confirm_modal.vue';

import {
  FEEDBACK_ISSUE_URL,
  I18N_GENERIC_ERROR,
  I18N_TOAST_SAVED,
  I18N_TOAST_DELETED,
  I18N_TOAST_ENABLED,
  I18N_TOAST_DISABLED,
} from '~/projects/settings_service_desk/custom_email_constants';
import {
  MOCK_CUSTOM_EMAIL_EMPTY,
  MOCK_CUSTOM_EMAIL_STARTED,
  MOCK_CUSTOM_EMAIL_FAILED,
  MOCK_CUSTOM_EMAIL_FINISHED,
  MOCK_CUSTOM_EMAIL_ENABLED,
  MOCK_CUSTOM_EMAIL_DISABLED,
  MOCK_CUSTOM_EMAIL_FORM_SUBMIT,
} from './mock_data';

describe('CustomEmailWrapper', () => {
  let axiosMock;
  let wrapper;

  const defaultProps = {
    incomingEmail: 'incoming@example.com',
    customEmailEndpoint: '/flightjs/Flight/-/service_desk/custom_email',
  };

  const defaultCustomEmailProps = {
    incomingEmail: defaultProps.incomingEmail,
    customEmail: 'user@example.com',
    smtpAddress: 'smtp.example.com',
  };

  const showToast = jest.fn();

  const createWrapper = (props = {}) => {
    wrapper = extendedWrapper(
      mount(CustomEmailWrapper, {
        propsData: { ...defaultProps, ...props },
        mocks: {
          $toast: {
            show: showToast,
          },
        },
      }),
    );
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findFeedbackLink = () => wrapper.findByTestId('feedback-link');
  const findCustomEmailForm = () => wrapper.findComponent(CustomEmailForm);
  const findCustomEmail = () => wrapper.findComponent(CustomEmail);
  const findCustomEmailConfirmModal = () => wrapper.findComponent(CustomEmailConfirmModal);

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
    jest.clearAllTimers();
  });

  it('displays link to feedback issue', () => {
    createWrapper();

    expect(findFeedbackLink().attributes('href')).toBe(FEEDBACK_ISSUE_URL);
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

    it('displays form', async () => {
      await waitForPromises();

      expect(findCustomEmailForm().exists()).toBe(true);
    });

    describe('when CustomEmailForm emits submit event with valid params', () => {
      beforeEach(() => {
        axiosMock
          .onPost(defaultProps.customEmailEndpoint)
          .replyOnce(HTTP_STATUS_OK, MOCK_CUSTOM_EMAIL_STARTED);
      });

      it('creates custom email and displays CustomEmail component', async () => {
        createWrapper();
        await nextTick();

        findCustomEmailForm().vm.$emit('submit', MOCK_CUSTOM_EMAIL_FORM_SUBMIT);

        expect(findCustomEmailForm().emitted('submit')).toEqual([[MOCK_CUSTOM_EMAIL_FORM_SUBMIT]]);
        await waitForPromises();

        expect(showToast).toHaveBeenCalledWith(I18N_TOAST_SAVED);

        expect(findCustomEmail().props()).toEqual({
          ...defaultCustomEmailProps,
          verificationState: 'started',
          verificationError: null,
          isEnabled: false,
          isSubmitting: false,
        });
      });
    });
  });

  describe('when initial resource loading return started verification', () => {
    beforeEach(async () => {
      axiosMock
        .onGet(defaultProps.customEmailEndpoint)
        .reply(HTTP_STATUS_OK, MOCK_CUSTOM_EMAIL_STARTED);

      createWrapper();
      await waitForPromises();
    });

    it('displays CustomEmail component', () => {
      expect(findCustomEmail().props()).toEqual({
        ...defaultCustomEmailProps,
        verificationState: 'started',
        verificationError: null,
        isEnabled: false,
        isSubmitting: false,
      });
    });

    it('schedules and executes polling', async () => {
      jest.runOnlyPendingTimers();
      await waitForPromises();

      // first after initial resource fetching, second after first polling
      expect(axiosMock.history.get).toHaveLength(2);
      expect(setTimeout).toHaveBeenCalledTimes(2);
      expect(setTimeout).toHaveBeenLastCalledWith(expect.any(Function), 8000);
    });

    describe('when CustomEmail triggers reset event', () => {
      beforeEach(() => {
        findCustomEmail().vm.$emit('reset');
      });

      it('shows confirm modal', () => {
        expect(findCustomEmailConfirmModal().props('visible')).toBe(true);
      });
    });

    it('deletes custom email on remove event', async () => {
      axiosMock
        .onDelete(defaultProps.customEmailEndpoint)
        .reply(HTTP_STATUS_OK, MOCK_CUSTOM_EMAIL_EMPTY);

      findCustomEmailConfirmModal().vm.$emit('remove');
      await waitForPromises();

      expect(axiosMock.history.delete).toHaveLength(1);
      expect(showToast).toHaveBeenCalledWith(I18N_TOAST_DELETED);

      expect(findCustomEmailForm().exists()).toBe(true);
    });
  });

  describe('when initial resource loading returns failed verification', () => {
    beforeEach(async () => {
      axiosMock
        .onGet(defaultProps.customEmailEndpoint)
        .reply(HTTP_STATUS_OK, MOCK_CUSTOM_EMAIL_FAILED);
      createWrapper();
      await waitForPromises();
    });

    it('fetches data from endpoint and displays CustomEmail component', () => {
      expect(findCustomEmail().props()).toEqual({
        ...defaultCustomEmailProps,
        verificationState: 'failed',
        verificationError: 'smtp_host_issue',
        isEnabled: false,
        isSubmitting: false,
      });
    });

    describe('when CustomEmail triggers reset event', () => {
      beforeEach(() => {
        findCustomEmail().vm.$emit('reset');
      });

      it('shows confirm modal', () => {
        expect(findCustomEmailConfirmModal().props('visible')).toBe(true);
      });
    });
  });

  describe('when initial resource loading returns finished verification', () => {
    beforeEach(async () => {
      axiosMock
        .onGet(defaultProps.customEmailEndpoint)
        .reply(HTTP_STATUS_OK, MOCK_CUSTOM_EMAIL_FINISHED);

      createWrapper();
      await waitForPromises();
    });

    it('fetches data from endpoint and displays CustomEmail component', () => {
      expect(findCustomEmail().props()).toEqual({
        ...defaultCustomEmailProps,
        verificationState: 'finished',
        verificationError: null,
        isEnabled: false,
        isSubmitting: false,
      });
    });

    describe('when CustomEmail triggers reset event', () => {
      beforeEach(() => {
        findCustomEmail().vm.$emit('reset');
      });

      it('shows confirm modal', () => {
        expect(findCustomEmailConfirmModal().props('visible')).toBe(true);
      });
    });

    it('enables custom email on toggle event', async () => {
      axiosMock
        .onPut(defaultProps.customEmailEndpoint)
        .reply(HTTP_STATUS_OK, MOCK_CUSTOM_EMAIL_ENABLED);

      findCustomEmail().vm.$emit('toggle', true);

      await waitForPromises();

      expect(axiosMock.history.put).toHaveLength(1);
      expect(showToast).toHaveBeenCalledWith(I18N_TOAST_ENABLED);

      expect(findCustomEmail().props()).toEqual({
        ...defaultCustomEmailProps,
        verificationState: 'finished',
        verificationError: null,
        isEnabled: true,
        isSubmitting: false,
      });
    });
  });

  describe('when initial resource loading returns enabled custom email', () => {
    beforeEach(async () => {
      axiosMock
        .onGet(defaultProps.customEmailEndpoint)
        .reply(HTTP_STATUS_OK, MOCK_CUSTOM_EMAIL_ENABLED);

      createWrapper();
      await waitForPromises();
    });

    it('fetches data from endpoint and displays CustomEmail component', () => {
      expect(findCustomEmail().props()).toEqual({
        ...defaultCustomEmailProps,
        verificationState: 'finished',
        verificationError: null,
        isEnabled: true,
        isSubmitting: false,
      });
    });

    it('disables custom email on toggle event', async () => {
      axiosMock
        .onPut(defaultProps.customEmailEndpoint)
        .reply(HTTP_STATUS_OK, MOCK_CUSTOM_EMAIL_DISABLED);

      findCustomEmail().vm.$emit('toggle', false);

      await waitForPromises();

      expect(axiosMock.history.put).toHaveLength(1);
      expect(showToast).toHaveBeenCalledWith(I18N_TOAST_DISABLED);

      expect(findCustomEmail().props()).toEqual({
        ...defaultCustomEmailProps,
        verificationState: 'finished',
        verificationError: null,
        isEnabled: false,
        isSubmitting: false,
      });
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
