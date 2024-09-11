import { GlForm, GlFormInput } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import EmailForm from '~/sessions/new/components/email_form.vue';
import { I18N_CANCEL, I18N_EMAIL_INVALID } from '~/sessions/new/constants';

const validEmailAddress = 'foo+bar@ema.il';
const invalidEmailAddress = 'invalid@ema@il';

describe('EmailForm', () => {
  let wrapper;

  const defaultProps = {
    error: '',
    formInfo: 'Form info',
    submitText: 'Submit',
  };

  const createComponent = (props = {}) => {
    wrapper = mountExtended(EmailForm, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findEmailInput = () => wrapper.findComponent(GlFormInput);
  const findSubmitButton = () => wrapper.find('[type="submit"]');
  const findCancelLink = () => wrapper.findByText(I18N_CANCEL);
  const enterEmail = (email) => findEmailInput().setValue(email);
  const submitForm = () => findForm().trigger('submit');

  beforeEach(() => {
    createComponent();
  });

  it('displays the correct submit button text', () => {
    expect(findSubmitButton().text()).toContain(defaultProps.submitText);
  });

  it('displays the passed in form info text', () => {
    expect(wrapper.text()).toContain(defaultProps.formInfo);
  });

  describe('on submit', () => {
    it('emits a submit-email event with the submitted email address', () => {
      enterEmail(validEmailAddress);

      submitForm();

      expect(wrapper.emitted('submit-email')[0]).toEqual([validEmailAddress]);
    });
  });

  describe('error messages', () => {
    describe('when trying to submit an invalid email address', () => {
      beforeEach(() => {
        enterEmail(invalidEmailAddress);
      });

      it('shows no error message before submitting the form', () => {
        expect(wrapper.text()).not.toContain(I18N_EMAIL_INVALID);
        expect(findSubmitButton().props('disabled')).toBe(false);
      });

      describe('when submitting the form', () => {
        beforeEach(() => {
          submitForm();
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

    describe('when error prop is not an empty string', () => {
      it('shows the error message and disables the submit button', async () => {
        const serverErrorMessage = 'server error message';

        createComponent({ error: serverErrorMessage });

        expect(wrapper.text()).not.toContain(serverErrorMessage);

        enterEmail(validEmailAddress);
        await nextTick();

        submitForm();
        await nextTick();

        expect(wrapper.text()).toContain(serverErrorMessage);
        expect(findSubmitButton().props('disabled')).toBe(true);
      });
    });
  });

  describe('when clicking the cancel link', () => {
    beforeEach(() => {
      findCancelLink().trigger('click');
    });

    it('emits a cancel event', () => {
      expect(wrapper.emitted('cancel')[0]).toEqual([]);
    });
  });
});
