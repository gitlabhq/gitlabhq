import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import ImportConfigTab from '~/import/offline_transfer/import/import_config_tab.vue';
import ObjectStorageFields from '~/import/offline_transfer/components/object_storage_fields.vue';

describe('ImportConfigTab', () => {
  let wrapper;

  const createComponent = ({ propsData = {}, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(ImportConfigTab, { propsData });
  };

  const findObjectStorageFields = () => wrapper.findComponent(ObjectStorageFields);
  const findExportPrefixInput = () => wrapper.findComponentByTestId('export-prefix-input');

  const storageConfig = {
    accessKeyId: 'AKIAEXAMPLE',
    secretAccessKey: 'mySecretKey',
    region: 'us-east-1',
    bucketName: 'my-bucket',
    pathStyle: false,
    exportPrefix: 'my-offline-export',
  };

  describe('object storage fields', () => {
    beforeEach(() => {
      createComponent({ propsData: { storageConfig } });
    });

    it('render as the import variant correctly', () => {
      expect(findObjectStorageFields().props()).toMatchObject({
        variant: 'import',
        value: storageConfig,
        validationAttempted: false,
      });
    });

    it('emit storage-input when a field changes', () => {
      const updated = { ...storageConfig, region: 'eu-west-1' };
      findObjectStorageFields().vm.$emit('input', updated);

      expect(wrapper.emitted('storage-input')).toEqual([[updated]]);
    });
  });

  describe('export prefix (additional) field', () => {
    beforeEach(() => {
      createComponent({ propsData: { storageConfig }, mountFn: mountExtended });
    });

    it('renders with the current prefix', () => {
      expect(findExportPrefixInput().props('value')).toBe('my-offline-export');
    });

    it('when changed emits the whole storage config with just the prefix changed', () => {
      findExportPrefixInput().vm.$emit('input', 'other-export');

      expect(wrapper.emitted('storage-input')).toEqual([
        [{ ...storageConfig, exportPrefix: 'other-export' }],
      ]);
    });
  });

  describe('validation', () => {
    it('marks an empty export prefix input as invalid', () => {
      createComponent({
        propsData: {
          storageConfig: { ...storageConfig, exportPrefix: '' },
          validationAttempted: true,
        },
        mountFn: mountExtended,
      });

      expect(findExportPrefixInput().attributes('aria-invalid')).toBe('true');
    });

    it('leaves a filled export prefix input as valid', () => {
      createComponent({
        propsData: { storageConfig, validationAttempted: true },
        mountFn: mountExtended,
      });

      expect(findExportPrefixInput().attributes('aria-invalid')).toBeUndefined();
    });
  });
});
