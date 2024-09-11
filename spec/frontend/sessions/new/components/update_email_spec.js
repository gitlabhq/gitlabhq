import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import UpdateEmail from '~/sessions/new/components/update_email.vue';
import EmailForm from '~/sessions/new/components/email_form.vue';
import {
  I18N_UPDATE_EMAIL,
  I18N_UPDATE_EMAIL_GUIDANCE,
  I18N_UPDATE_EMAIL_SUCCESS,
  I18N_GENERIC_ERROR,
  SUCCESS_RESPONSE,
  FAILURE_RESPONSE,
} from '~/sessions/new/constants';

const email = 'foo+bar@ema.il';

jest.mock('~/alert');

describe('UpdateEmail', () => {
  let wrapper;
  let axiosMock;

  const provide = {
    updateEmailPath: '/users/update_email',
  };

  const createComponent = () => {
    wrapper = mountExtended(UpdateEmail, { provide });
  };

  const findEmailForm = () => wrapper.findComponent(EmailForm);
  const submitEmailForm = () => findEmailForm().vm.$emit('submit-email', email);
  const mockUpdateEmailEndpoint = (response) => {
    axiosMock.onPatch(provide.updateEmailPath, { user: { email } }).reply(HTTP_STATUS_OK, response);
  };

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    createComponent();
  });

  afterEach(() => {
    createAlert.mockClear();
    axiosMock.restore();
  });

  it('renders EmailForm with the correct props', () => {
    expect(findEmailForm().props()).toMatchObject({
      error: '',
      formInfo: I18N_UPDATE_EMAIL_GUIDANCE,
      submitText: I18N_UPDATE_EMAIL,
    });
  });

  describe('when successfully verifying the email address', () => {
    beforeEach(async () => {
      mockUpdateEmailEndpoint({ status: SUCCESS_RESPONSE });
      submitEmailForm();

      await axios.waitForAll();
    });

    it('shows a successfully updated alert', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: I18N_UPDATE_EMAIL_SUCCESS,
        variant: VARIANT_SUCCESS,
      });
    });

    it('emits a verifyToken event with the updated email address', () => {
      expect(wrapper.emitted('verifyToken')[0]).toEqual([email]);
    });
  });

  describe('error messages', () => {
    describe('when the server responds with an error message', () => {
      it('passes the error as error prop to EmailForm', async () => {
        const serverErrorMessage = 'server error message';

        mockUpdateEmailEndpoint({ status: FAILURE_RESPONSE, message: serverErrorMessage });
        submitEmailForm();

        await axios.waitForAll();

        expect(findEmailForm().props('error')).toBe(serverErrorMessage);
      });
    });

    describe('when the server responds unexpectedly', () => {
      it.each`
        scenario                       | statusCode
        ${'the response is undefined'} | ${HTTP_STATUS_OK}
        ${'the request failed'}        | ${HTTP_STATUS_NOT_FOUND}
      `(`shows an alert when $scenario`, async ({ statusCode }) => {
        axiosMock.onPatch(provide.updateEmailPath).replyOnce(statusCode);
        submitEmailForm();

        await axios.waitForAll();

        expect(createAlert).toHaveBeenCalledWith({
          message: I18N_GENERIC_ERROR,
          captureError: true,
          error: expect.any(Error),
        });
      });
    });
  });

  describe('when EmailForm emits cancel event', () => {
    it('emits a verifyToken event without an email address', () => {
      findEmailForm().vm.$emit('cancel');

      expect(wrapper.emitted('verifyToken')[0]).toEqual([]);
    });
  });
});
