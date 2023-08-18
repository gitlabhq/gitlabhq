import { GlForm, GlFormInput } from '@gitlab/ui';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import UpdateEmail from '~/sessions/new/components/update_email.vue';
import {
  I18N_CANCEL,
  I18N_EMAIL_INVALID,
  I18N_UPDATE_EMAIL_SUCCESS,
  I18N_GENERIC_ERROR,
  SUCCESS_RESPONSE,
  FAILURE_RESPONSE,
} from '~/sessions/new/constants';

const validEmailAddress = 'foo+bar@ema.il';
const invalidEmailAddress = 'invalid@ema@il';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('EmailVerification', () => {
  let wrapper;
  let axiosMock;

  const defaultPropsData = {
    updateEmailPath: '/users/update_email',
  };

  const createComponent = (props = {}) => {
    wrapper = mountExtended(UpdateEmail, {
      propsData: { ...defaultPropsData, ...props },
    });
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findEmailInput = () => wrapper.findComponent(GlFormInput);
  const findSubmitButton = () => wrapper.find('[type="submit"]');
  const findCancelLink = () => wrapper.findByText(I18N_CANCEL);
  const enterEmail = (email) => findEmailInput().setValue(email);
  const submitForm = () => findForm().trigger('submit');

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    createComponent();
  });

  afterEach(() => {
    createAlert.mockClear();
    axiosMock.restore();
  });

  describe('when successfully verifying the email address', () => {
    beforeEach(async () => {
      enterEmail(validEmailAddress);

      axiosMock
        .onPatch(defaultPropsData.updateEmailPath)
        .reply(HTTP_STATUS_OK, { status: SUCCESS_RESPONSE });

      submitForm();
      await axios.waitForAll();
    });

    it('shows a successfully updated alert', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: I18N_UPDATE_EMAIL_SUCCESS,
        variant: VARIANT_SUCCESS,
      });
    });

    it('emits a verifyToken event with the updated email address', () => {
      expect(wrapper.emitted('verifyToken')[0]).toEqual([validEmailAddress]);
    });
  });

  describe('error messages', () => {
    beforeEach(() => {
      enterEmail(invalidEmailAddress);
    });

    describe('when trying to submit an invalid email address', () => {
      it('shows no error message before submitting the form', () => {
        expect(wrapper.text()).not.toContain(I18N_EMAIL_INVALID);
        expect(findSubmitButton().props('disabled')).toBe(false);
      });

      describe('when submitting the form', () => {
        beforeEach(async () => {
          submitForm();
          await axios.waitForAll();
        });

        it('shows an error message and disables the submit button', () => {
          expect(wrapper.text()).toContain(I18N_EMAIL_INVALID);
          expect(findSubmitButton().props('disabled')).toBe(true);
        });

        describe('when entering a valid email address', () => {
          beforeEach(() => {
            enterEmail(validEmailAddress);
          });

          it('hides the error message and enables the submit button again', () => {
            expect(wrapper.text()).not.toContain(I18N_EMAIL_INVALID);
            expect(findSubmitButton().props('disabled')).toBe(false);
          });
        });
      });
    });

    describe('when the server responds with an error message', () => {
      const serverErrorMessage = 'server error message';

      beforeEach(async () => {
        enterEmail(validEmailAddress);

        axiosMock
          .onPatch(defaultPropsData.updateEmailPath)
          .replyOnce(HTTP_STATUS_OK, { status: FAILURE_RESPONSE, message: serverErrorMessage });

        submitForm();
        await axios.waitForAll();
      });

      it('shows the error message and disables the submit button', () => {
        expect(wrapper.text()).toContain(serverErrorMessage);
        expect(findSubmitButton().props('disabled')).toBe(true);
      });

      describe('when entering a valid email address', () => {
        beforeEach(async () => {
          await enterEmail('');
          enterEmail(validEmailAddress);
        });

        it('hides the error message and enables the submit button again', () => {
          expect(wrapper.text()).not.toContain(serverErrorMessage);
          expect(findSubmitButton().props('disabled')).toBe(false);
        });
      });
    });

    describe('when the server responds unexpectedly', () => {
      it.each`
        scenario                       | statusCode
        ${'the response is undefined'} | ${HTTP_STATUS_OK}
        ${'the request failed'}        | ${HTTP_STATUS_NOT_FOUND}
      `(`shows an alert when $scenario`, async ({ statusCode }) => {
        enterEmail(validEmailAddress);

        axiosMock.onPatch(defaultPropsData.updateEmailPath).replyOnce(statusCode);

        submitForm();

        await axios.waitForAll();

        expect(createAlert).toHaveBeenCalledWith({
          message: I18N_GENERIC_ERROR,
          captureError: true,
          error: expect.any(Error),
        });
      });
    });
  });

  describe('when clicking the cancel link', () => {
    beforeEach(() => {
      findCancelLink().trigger('click');
    });

    it('emits a verifyToken event without an email address', () => {
      expect(wrapper.emitted('verifyToken')[0]).toEqual([]);
    });
  });
});
