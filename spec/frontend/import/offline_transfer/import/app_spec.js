import { nextTick } from 'vue';
import { GlAlert, GlFormCheckbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import OfflineTransferImportApp from '~/import/offline_transfer/import/app.vue';
import FormStepper from '~/import/offline_transfer/components/form_stepper.vue';
import ImportConfigTab from '~/import/offline_transfer/import/import_config_tab.vue';
import SelectDestinationTab from '~/import/offline_transfer/import/select_destination_tab.vue';
import { mockGroups } from '../mock_data';

describe('OfflineTransferImportApp', () => {
  let wrapper;

  const createComponent = ({ mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(OfflineTransferImportApp);
  };

  const existingGroup = 'existing_group';
  const [parentGroup] = mockGroups;
  const validStorageConfig = {
    accessKeyId: 'AKIAEXAMPLE',
    secretAccessKey: 'mySecretKey',
    region: 'us-east-1',
    bucketName: 'my-bucket',
    pathStyle: false,
    exportPrefix: 'my-export',
  };
  const findFormStepper = () => wrapper.findComponent(FormStepper);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findSelectDestinationTab = () => wrapper.findComponent(SelectDestinationTab);
  const findImportConfigTab = () => wrapper.findComponent(ImportConfigTab);
  const findReviewTab = () => wrapper.findByTestId('review-import-tab');

  beforeEach(() => {
    createComponent();
  });

  describe('passes to FormStepper', () => {
    it('the correct steps', () => {
      expect(findFormStepper().props('steps')).toStrictEqual([
        'Select destination',
        'Configure',
        'Import',
      ]);
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

  describe('select destination tab', () => {
    it('is passed `top-level` as the initial import destination', () => {
      expect(findSelectDestinationTab().props('destinationSelection')).toEqual({
        type: 'top_level',
        parentGroup: null,
      });
    });

    it('is passed the updated selection back down after the tab emits destination-input', async () => {
      const selection = { type: existingGroup, parentGroup };
      findSelectDestinationTab().vm.$emit('destination-input', selection);
      await nextTick();

      expect(findSelectDestinationTab().props('destinationSelection')).toEqual(selection);
    });

    describe('validation', () => {
      const setDestination = async (selection) => {
        findSelectDestinationTab().vm.$emit('destination-input', selection);
        await nextTick();
      };

      it('passes with the default top-level destination', () => {
        expect(findFormStepper().props('validateStep')(0)).toBe(true);
      });

      it('fails when an existing group is chosen without a parent', async () => {
        await setDestination({ type: existingGroup, parentGroup: null });

        expect(findFormStepper().props('validateStep')(0)).toBe(false);
      });

      it('passes once a parent group is chosen', async () => {
        await setDestination({ type: existingGroup, parentGroup });

        expect(findFormStepper().props('validateStep')(0)).toBe(true);
      });

      it('registers as validationAttempted when step validation fails', async () => {
        findFormStepper().vm.$emit('validation-failed', 0);
        await nextTick();

        expect(findSelectDestinationTab().props('validationAttempted')).toBe(true);
      });

      it('clears after the corrected step is left', async () => {
        findFormStepper().vm.$emit('validation-failed', 0);
        await nextTick();
        findFormStepper().vm.$emit('stepped-forward', { previousTabIndex: 0 });
        await nextTick();

        expect(findSelectDestinationTab().props('validationAttempted')).toBe(false);
      });
    });
  });

  describe('configure tab', () => {
    const setStorageConfig = async (config) => {
      findImportConfigTab().vm.$emit('storage-input', config);
      await nextTick();
    };

    it('receives an empty initial AWS storage config', () => {
      expect(findImportConfigTab().props('storageConfig')).toEqual({
        accessKeyId: '',
        secretAccessKey: '',
        region: '',
        bucketName: '',
        pathStyle: false,
        exportPrefix: '',
      });
    });

    it('receives the updated storage config back down after the tab emits storage-input', async () => {
      await setStorageConfig(validStorageConfig);

      expect(findImportConfigTab().props('storageConfig')).toEqual(validStorageConfig);
    });

    describe('validation', () => {
      it('fails with an empty initial storage config', () => {
        expect(findFormStepper().props('validateStep')(1)).toBe(false);
      });

      it('fails when the storage config has no export prefix', async () => {
        await setStorageConfig({ ...validStorageConfig, exportPrefix: '' });

        expect(findFormStepper().props('validateStep')(1)).toBe(false);
      });

      it('passes with a complete storage config', async () => {
        await setStorageConfig(validStorageConfig);

        expect(findFormStepper().props('validateStep')(1)).toBe(true);
      });

      it('registers as validationAttempted when step validation fails', async () => {
        findFormStepper().vm.$emit('validation-failed', 1);
        await nextTick();

        expect(findImportConfigTab().props('validationAttempted')).toBe(true);
      });

      it('clears after the corrected step is left', async () => {
        findFormStepper().vm.$emit('validation-failed', 1);
        await nextTick();
        findFormStepper().vm.$emit('stepped-forward', { previousTabIndex: 1 });
        await nextTick();

        expect(findImportConfigTab().props('validationAttempted')).toBe(false);
      });
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
