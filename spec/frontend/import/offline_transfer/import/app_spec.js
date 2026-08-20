import { GlAlert, GlFormCheckbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import OfflineTransferImportApp from '~/import/offline_transfer/import/app.vue';
import FormStepper from '~/import/offline_transfer/components/form_stepper.vue';

describe('OfflineTransferImportApp', () => {
  let wrapper;

  const createComponent = ({ mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(OfflineTransferImportApp);
  };

  const findFormStepper = () => wrapper.findComponent(FormStepper);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findConfigureTab = () => wrapper.findByTestId('configure-tab');
  const findReviewTab = () => wrapper.findByTestId('review-import-tab');

  beforeEach(() => {
    createComponent();
  });

  describe('header', () => {
    it('renders the correct heading text', () => {
      expect(wrapper.find('h1').text()).toBe('Import for offline transfer');
    });
  });

  describe('passes to FormStepper', () => {
    it('the correct steps', () => {
      expect(findFormStepper().props('steps')).toStrictEqual(['Configure', 'Import']);
    });

    it('the correct completion button text', () => {
      expect(findFormStepper().props('completionButtonText')).toBe('Start import');
    });

    it('validateStep as a function', () => {
      expect(findFormStepper().props('validateStep')).toBeInstanceOf(Function);
    });

    it('isFormComplete as false', () => {
      expect(findFormStepper().props('isFormComplete')).toBe(false);
    });
  });

  describe('configure tab', () => {
    it('renders with the correct text', () => {
      expect(findConfigureTab().findComponent(GlFormCheckbox).text()).toBe('Select destination');
    });
  });

  describe('review tab', () => {
    it('renders with the correct text', () => {
      expect(findReviewTab().findComponent(GlFormCheckbox).text()).toBe('Review and import');
    });
  });

  describe('form submission', () => {
    it('renders the success UI', async () => {
      expect(findAlert().exists()).toBe(false);
      findFormStepper().vm.$emit('complete');
      await waitForPromises();

      expect(findAlert().props('title')).toBe('Complete');
      expect(findReviewTab().findComponent(GlFormCheckbox).exists()).toBe(false);
      expect(findReviewTab().text()).toBe('Import has started.');
    });
  });
});
