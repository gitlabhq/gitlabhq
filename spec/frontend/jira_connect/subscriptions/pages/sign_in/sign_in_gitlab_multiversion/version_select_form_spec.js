import { GlFormInput, GlFormRadioGroup, GlForm } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import VersionSelectForm from '~/jira_connect/subscriptions/pages/sign_in/sign_in_gitlab_multiversion/version_select_form.vue';
import SelfManagedAlert from '~/jira_connect/subscriptions/pages/sign_in/sign_in_gitlab_multiversion/self_managed_alert.vue';
import SetupInstructions from '~/jira_connect/subscriptions/pages/sign_in/sign_in_gitlab_multiversion/setup_instructions.vue';

describe('VersionSelectForm', () => {
  let wrapper;

  const findFormRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findForm = () => wrapper.findComponent(GlForm);
  const findInput = () => wrapper.findComponent(GlFormInput);
  const findSelfManagedAlert = () => wrapper.findComponent(SelfManagedAlert);
  const findSetupInstructions = () => wrapper.findComponent(SetupInstructions);
  const findBackButton = () => wrapper.findByTestId('back-button');
  const findSubmitButton = () => wrapper.findByTestId('submit-button');

  const submitForm = () => findForm().vm.$emit('submit', new Event('submit'));

  const expectSelfManagedFlowAtStep = (step) => {
    // step 0 is for SaaS which doesn't have any of the self-managed elements
    const expectSelfManagedAlert = step === 1;
    const expectSetupInstructions = step === 2;
    const expectSelfManagedInput = step === 3;

    it(`${expectSelfManagedAlert ? 'renders' : 'does not render'} self-managed alert`, () => {
      expect(findSelfManagedAlert().exists()).toBe(expectSelfManagedAlert);
    });

    it(`${expectSetupInstructions ? 'renders' : 'does not render'} setup instructions`, () => {
      expect(findSetupInstructions().exists()).toBe(expectSetupInstructions);
    });

    it(`${
      expectSelfManagedInput ? 'renders' : 'does not render'
    } self-managed instance URL input`, () => {
      expect(findInput().exists()).toBe(expectSelfManagedInput);
    });
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(VersionSelectForm);
  };

  describe('when "SaaS" radio option is selected (default state)', () => {
    beforeEach(() => {
      createComponent();
    });

    it('selects "saas" radio option by default', () => {
      expect(findFormRadioGroup().vm.$attrs.checked).toBe(VersionSelectForm.radioOptions.saas);
    });

    it('renders submit button as "Save"', () => {
      expect(findSubmitButton().text()).toBe(VersionSelectForm.i18n.buttonSave);
    });

    expectSelfManagedFlowAtStep(0);

    describe('when form is submitted', () => {
      it('emits "submit" event with gitlab.com as the payload', () => {
        submitForm();

        expect(wrapper.emitted('submit')[0][0]).toBe('https://gitlab.com');
      });
    });
  });

  describe('when "self-managed" radio option is selected (step 1 of 3)', () => {
    beforeEach(() => {
      createComponent();

      findFormRadioGroup().vm.$emit('input', VersionSelectForm.radioOptions.selfManaged);
    });

    it('renders submit button as "Next"', () => {
      expect(findSubmitButton().text()).toBe(VersionSelectForm.i18n.buttonNext);
    });

    expectSelfManagedFlowAtStep(1);

    describe('when user clicks "Next" button (next to step 2 of 3)', () => {
      beforeEach(() => {
        submitForm();
      });

      expectSelfManagedFlowAtStep(2);

      describe('when SetupInstructions emits `next` event (next to step 3 of 3)', () => {
        beforeEach(() => {
          findSetupInstructions().vm.$emit('next');
        });

        expectSelfManagedFlowAtStep(3);

        describe('when form is submitted', () => {
          it('emits "submit" event with the input field value as the payload', () => {
            const mockInstanceUrl = 'https://gitlab.example.com';

            findInput().vm.$emit('input', mockInstanceUrl);
            submitForm();

            expect(wrapper.emitted('submit')[0][0]).toBe(mockInstanceUrl);
          });
        });

        describe('when back button is clicked', () => {
          beforeEach(() => {
            findBackButton().vm.$emit('click', {
              preventDefault: jest.fn(), // preventDefault is needed to prevent form submission
            });
          });

          expectSelfManagedFlowAtStep(1);
        });
      });

      describe('when SetupInstructions emits `back` event (back to step 1 of 3)', () => {
        beforeEach(() => {
          findSetupInstructions().vm.$emit('back');
        });

        expectSelfManagedFlowAtStep(1);
      });
    });
  });
});
