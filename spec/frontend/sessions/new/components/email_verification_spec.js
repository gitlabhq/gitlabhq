import { GlForm, GlFormInput } from '@gitlab/ui';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import EmailVerification from '~/sessions/new/components/email_verification.vue';
import EmailForm from '~/sessions/new/components/email_form.vue';
import UpdateEmail from '~/sessions/new/components/update_email.vue';
import { visitUrl } from '~/lib/utils/url_utility';
import {
  I18N_EMAIL_EMPTY_CODE,
  I18N_EMAIL_INVALID_CODE,
  I18N_GENERIC_ERROR,
  I18N_UPDATE_EMAIL,
  I18N_RESEND_LINK,
  I18N_EMAIL_RESEND_SUCCESS,
  I18N_SEND_TO_SECONDARY_EMAIL_BUTTON_TEXT,
  I18N_SEND_TO_SECONDARY_EMAIL_GUIDE,
} from '~/sessions/new/constants';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('EmailVerification', () => {
  let wrapper;
  let axiosMock;

  const defaultPropsData = {
    username: 'al12',
    obfuscatedEmail: 'al**@g*****.com',
    verifyPath: '/users/sign_in',
    resendPath: '/users/resend_verification_code',
    isOfferEmailReset: true,
  };

  const createComponent = ({ props, provide } = { props: {}, provide: {} }) => {
    wrapper = mountExtended(EmailVerification, {
      propsData: { ...defaultPropsData, ...props },
      provide: { ...provide, updateEmailPath: '/users/update_email' },
    });
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findSecondaryEmailForm = () => wrapper.findComponent(EmailForm);
  const findCodeInput = () => wrapper.findComponent(GlFormInput);
  const findUpdateEmail = () => wrapper.findComponent(UpdateEmail);
  const findSubmitButton = () => wrapper.find('[type="submit"]');
  const findResendLink = () => wrapper.findByText(I18N_RESEND_LINK);
  const findShowSecondaryEmailFormLink = () =>
    wrapper.findByText(I18N_SEND_TO_SECONDARY_EMAIL_BUTTON_TEXT);
  const findUpdateEmailLink = () => wrapper.findByText(I18N_UPDATE_EMAIL);
  const enterCode = (code) => findCodeInput().setValue(code);
  const submitForm = () => findForm().trigger('submit');

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    createComponent();
  });

  afterEach(() => {
    createAlert.mockClear();
    axiosMock.restore();
  });

  describe('rendering the form', () => {
    it('contains the obfuscated email address', () => {
      expect(wrapper.text()).toContain(defaultPropsData.obfuscatedEmail);
    });

    it("contains the user's username", () => {
      expect(wrapper.text()).toContain(`You are signed in as ${defaultPropsData.username}`);
    });

    it('contains help text describing option to verification code to secondary email and a link to support page', () => {
      expect(wrapper.text()).toMatch(
        /If you don't have access to the primary email address, you can.*send a code to another address associated with this account, or you can try to verify another way./,
      );
    });

    it('renders the link to show secondary email form', () => {
      expect(findShowSecondaryEmailFormLink().exists()).toBe(true);
    });

    it('does not render EmailForm for sending code to secondary email initially', () => {
      expect(findSecondaryEmailForm().exists()).toBe(false);
    });
  });

  describe('verifying the code', () => {
    describe('when successfully verifying the code', () => {
      const redirectPath = 'root';

      beforeEach(async () => {
        enterCode('123456');

        axiosMock
          .onPost(defaultPropsData.verifyPath)
          .reply(HTTP_STATUS_OK, { status: 'success', redirect_path: redirectPath });

        await submitForm();
        await axios.waitForAll();
      });

      it('redirects to the returned redirect path', () => {
        expect(visitUrl).toHaveBeenCalledWith(redirectPath);
      });
    });

    describe('error messages', () => {
      it.each`
        scenario                                                         | code        | submit   | codeValid | errorShown | message
        ${'shows no error messages before submitting the form'}          | ${''}       | ${false} | ${false}  | ${false}   | ${null}
        ${'shows no error messages before submitting the form'}          | ${'xxx'}    | ${false} | ${false}  | ${false}   | ${null}
        ${'shows no error messages before submitting the form'}          | ${'123456'} | ${false} | ${true}   | ${false}   | ${null}
        ${'shows empty code error message when submitting the form'}     | ${''}       | ${true}  | ${false}  | ${true}    | ${I18N_EMAIL_EMPTY_CODE}
        ${'shows invalid error message when submitting the form'}        | ${'xxx'}    | ${true}  | ${false}  | ${true}    | ${I18N_EMAIL_INVALID_CODE}
        ${'shows incorrect code error message returned from the server'} | ${'123456'} | ${true}  | ${true}   | ${true}    | ${'The code is incorrect. Enter it again, or send a new code.'}
      `(`$scenario with code $code`, async ({ code, submit, codeValid, errorShown, message }) => {
        enterCode(code);

        if (submit && codeValid) {
          axiosMock
            .onPost(defaultPropsData.verifyPath)
            .replyOnce(HTTP_STATUS_OK, { status: 'failure', message });
        }

        if (submit) {
          await submitForm();
          await axios.waitForAll();
        }

        expect(findCodeInput().classes('is-invalid')).toBe(errorShown);
        expect(findSubmitButton().props('disabled')).toBe(errorShown);
        if (message) expect(wrapper.text()).toContain(message);
      });

      it('keeps showing error messages for invalid codes after submitting the form', async () => {
        const serverErrorMessage = 'error message';

        enterCode('123456');

        axiosMock
          .onPost(defaultPropsData.verifyPath)
          .replyOnce(HTTP_STATUS_OK, { status: 'failure', message: serverErrorMessage });

        await submitForm();
        await axios.waitForAll();

        expect(wrapper.text()).toContain(serverErrorMessage);

        await enterCode('');
        expect(wrapper.text()).toContain(I18N_EMAIL_EMPTY_CODE);

        await enterCode('xxx');
        expect(wrapper.text()).toContain(I18N_EMAIL_INVALID_CODE);
      });

      it('captures the error and shows an alert message when the request failed', async () => {
        enterCode('123456');

        axiosMock.onPost(defaultPropsData.verifyPath).replyOnce(HTTP_STATUS_OK, null);

        await submitForm();
        await axios.waitForAll();

        expect(createAlert).toHaveBeenCalledWith({
          message: I18N_GENERIC_ERROR,
          captureError: true,
          error: expect.any(Error),
        });
      });

      it('captures the error and shows an alert message when the request undefined', async () => {
        enterCode('123456');

        axiosMock.onPost(defaultPropsData.verifyPath).reply(HTTP_STATUS_OK, { status: undefined });

        await submitForm();
        await axios.waitForAll();

        expect(createAlert).toHaveBeenCalledWith({
          message: I18N_GENERIC_ERROR,
          captureError: true,
          error: undefined,
        });
      });
    });
  });

  describe('resending the code', () => {
    const failedMessage = 'Failure sending the code';
    const successAlertObject = {
      message: I18N_EMAIL_RESEND_SUCCESS,
      variant: VARIANT_SUCCESS,
    };
    const failedAlertObject = {
      message: failedMessage,
    };
    const undefinedAlertObject = {
      captureError: true,
      error: undefined,
      message: I18N_GENERIC_ERROR,
    };
    const genericAlertObject = {
      message: I18N_GENERIC_ERROR,
      captureError: true,
      error: expect.any(Error),
    };

    describe.each`
      scenario                                    | statusCode               | response                                         | alertObject
      ${'resend was successful'}                  | ${HTTP_STATUS_OK}        | ${{ status: 'success' }}                         | ${successAlertObject}
      ${'there was a problem resending the code'} | ${HTTP_STATUS_OK}        | ${{ status: 'failure', message: failedMessage }} | ${failedAlertObject}
      ${'the response status is undefined'}       | ${HTTP_STATUS_OK}        | ${{ status: undefined }}                         | ${undefinedAlertObject}
      ${'the request failed'}                     | ${HTTP_STATUS_NOT_FOUND} | ${null}                                          | ${genericAlertObject}
    `(`displayed alert message when $scenario`, ({ statusCode, response, alertObject }) => {
      beforeEach(() => {
        createComponent();

        enterCode('xxx');
      });

      it('is correct when "Resend" button (resend to primary email) is clicked', async () => {
        axiosMock
          .onPost(defaultPropsData.resendPath, { user: { email: '' } })
          .replyOnce(statusCode, response);

        findResendLink().trigger('click');

        await axios.waitForAll();

        expect(createAlert).toHaveBeenCalledWith(alertObject);
        expect(findCodeInput().element.value).toBe('');
      });

      it('is correct when resending to secondary email', async () => {
        const secondaryEmail = 'user_secondary@ema.il';

        axiosMock
          .onPost(defaultPropsData.resendPath, { user: { email: secondaryEmail } })
          .replyOnce(statusCode, response);

        await findShowSecondaryEmailFormLink().trigger('click');

        findSecondaryEmailForm().vm.$emit('submit-email', secondaryEmail);

        await axios.waitForAll();

        expect(createAlert).toHaveBeenCalledWith(alertObject);
        expect(findCodeInput().element.value).toBe('');
      });
    });
  });

  describe('updating the email', () => {
    it('contains the link to show the update email form', () => {
      expect(findUpdateEmailLink().exists()).toBe(true);
    });

    describe('when the isOfferEmailReset property is set to false', () => {
      beforeEach(() => {
        createComponent({ props: { isOfferEmailReset: false } });
      });

      it('does not contain the link to show the update email form', () => {
        expect(findUpdateEmailLink().exists()).toBe(false);
      });
    });

    it('shows the UpdateEmail component when clicking the link', async () => {
      expect(findUpdateEmail().exists()).toBe(false);

      await findUpdateEmailLink().trigger('click');

      expect(findUpdateEmail().exists()).toBe(true);
    });

    describe('when the UpdateEmail component triggers verifyToken', () => {
      const newEmail = 'new@ema.il';

      beforeEach(async () => {
        enterCode('123');
        await findUpdateEmailLink().trigger('click');
        findUpdateEmail().vm.$emit('verifyToken', newEmail);
      });

      it('hides the UpdateEmail component, shows the updated email address and resets the form', () => {
        expect(findUpdateEmail().exists()).toBe(false);
        expect(wrapper.text()).toContain(newEmail);
        expect(findCodeInput().element.value).toBe('');
      });
    });
  });

  describe('secondary email form', () => {
    beforeEach(() => {
      createComponent();
    });

    it('is shown when the show link is clicked', async () => {
      expect(findSecondaryEmailForm().exists()).toBe(false);

      await findShowSecondaryEmailFormLink().trigger('click');

      expect(findSecondaryEmailForm().exists()).toBe(true);
      expect(findSecondaryEmailForm().props()).toMatchObject({
        formInfo: I18N_SEND_TO_SECONDARY_EMAIL_GUIDE,
        submitText: I18N_RESEND_LINK,
      });
    });

    describe('when it emits a submit-email event', () => {
      it('hides the email form, shows the submitted secondary email, and resets the verification code form', async () => {
        const secondaryEmail = 'user_secondary@ema.il';

        enterCode('123');

        await findShowSecondaryEmailFormLink().trigger('click');

        findSecondaryEmailForm().vm.$emit('submit-email', secondaryEmail);

        await nextTick();

        expect(findSecondaryEmailForm().exists()).toBe(false);
        expect(wrapper.text()).toContain(secondaryEmail);
        expect(findCodeInput().element.value).toBe('');
      });
    });

    describe('when it emits a cancel event', () => {
      it('hides the email form, and resets the verification code form', async () => {
        enterCode('123');

        await findShowSecondaryEmailFormLink().trigger('click');

        findSecondaryEmailForm().vm.$emit('cancel');

        await nextTick();

        expect(findSecondaryEmailForm().exists()).toBe(false);
        expect(findCodeInput().element.value).toBe('');
      });
    });
  });
});
