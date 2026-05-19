import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OfflineTransferExportApp from '~/import/offline_transfer/export/app.vue';
import FormStepper from '~/import/offline_transfer/components/form_stepper.vue';
import { OFFLINE_EXPORT_STEPS } from '~/import/offline_transfer/constants';

describe('OfflineTransferExportApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(OfflineTransferExportApp);
  };

  const findFormStepper = () => wrapper.findComponent(FormStepper);
  const findCompletionAlert = () => wrapper.findByTestId('completion-alert');
  const findValidationErrorAlert = () => wrapper.findByTestId('validation-alert');

  describe('passes to FormStepper', () => {
    beforeEach(() => {
      createComponent();
    });

    it('the correct steps', () => {
      expect(findFormStepper().props('steps')).toBe(OFFLINE_EXPORT_STEPS);
    });

    it('the correct completion button text', () => {
      expect(findFormStepper().props('completionButtonText')).toBe('Start export');
    });

    it('validateStep as a function', () => {
      expect(findFormStepper().props('validateStep')).toBeInstanceOf(Function);
    });
  });

  // TODO: Replace tests as form contents are added.
  describe('events', () => {
    beforeEach(() => {
      createComponent();
    });

    it('triggers a completion alert when FormStepper emits complete', async () => {
      expect(findCompletionAlert().exists()).toBe(false);

      await findFormStepper().vm.$emit('complete');

      expect(findCompletionAlert().exists()).toBe(true);
    });

    it('triggers a validation error alert when FormStepper emits validation-failed', async () => {
      expect(findValidationErrorAlert().exists()).toBe(false);

      await findFormStepper().vm.$emit('validation-failed');

      expect(findValidationErrorAlert().exists()).toBe(true);
    });

    it('resets the previous step when FormStepper emits stepped-back', async () => {
      wrapper.vm.formData.configure = true;
      await nextTick();
      expect(wrapper.vm.formData.configure).toBe(true);

      await findFormStepper().vm.$emit('stepped-back', {
        previousTabIndex: 1,
      });
      await nextTick();
      expect(wrapper.vm.formData.configure).toBe(false);
    });
  });
});
