import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import { assertProps } from 'helpers/assert_props';
import ObjectStorageFields from '~/import/offline_transfer/components/object_storage_fields.vue';
import PasswordInput from '~/authentication/password/components/password_input.vue';

describe('ObjectStorageFields', () => {
  let wrapper;

  const mockValue = {
    accessKeyId: 'AKIAEXAMPLE',
    secretAccessKey: 'super',
    region: 'eu-west-1',
    bucketName: 'my-export-bucket',
    pathStyle: true,
  };

  const createComponent = ({ props = {}, mountFn = shallowMountExtended, slots = {} } = {}) => {
    wrapper = mountFn(ObjectStorageFields, {
      propsData: { variant: 'export', ...props },
      slots,
    });
  };

  const findAccessKeyId = () => wrapper.findComponentByTestId('access-key-id-input');
  const findSecretAccessKey = () => wrapper.findComponent(PasswordInput);
  const findRegion = () => wrapper.findComponentByTestId('region-input');
  const findBucketName = () => wrapper.findComponentByTestId('bucket-name-input');
  const findBucketNameGroup = () => wrapper.findByTestId('bucket-name-group');
  const findPathStyle = () => wrapper.findComponentByTestId('path-style-checkbox');

  it('renders AWS S3 configuration fields correctly', () => {
    createComponent();

    expect(findAccessKeyId().props('value')).toBe('');
    expect(findAccessKeyId().attributes('placeholder')).toBeUndefined();
    expect(findRegion().attributes('placeholder')).toBe('us-east-1');
    expect(findRegion().props('value')).toBe('');
    expect(findSecretAccessKey().props()).toMatchObject({
      required: false,
      autocomplete: 'new-password',
    });
    expect(findBucketName().props('value')).toBe('');
    expect(findPathStyle().props('checked')).toBe(false);
  });

  describe('when a value is provided renders', () => {
    beforeEach(() => createComponent({ props: { value: mockValue } }));

    it('each field with the correct value', () => {
      expect(findAccessKeyId().props('value')).toBe(mockValue.accessKeyId);
      expect(findSecretAccessKey().props('value')).toBe(mockValue.secretAccessKey);
      expect(findRegion().props('value')).toBe(mockValue.region);
      expect(findBucketName().props('value')).toBe(mockValue.bucketName);
      expect(findPathStyle().props('checked')).toBe(true);
    });
  });

  describe('emits', () => {
    beforeEach(() => createComponent({ props: { value: mockValue } }));

    it.each`
      field              | findField              | event       | eventPayload      | key
      ${'access key ID'} | ${findAccessKeyId}     | ${'input'}  | ${'NEWKEY'}       | ${'accessKeyId'}
      ${'secret key'}    | ${findSecretAccessKey} | ${'input'}  | ${'new-secret'}   | ${'secretAccessKey'}
      ${'region'}        | ${findRegion}          | ${'input'}  | ${'us-east-2'}    | ${'region'}
      ${'bucket name'}   | ${findBucketName}      | ${'input'}  | ${'other-bucket'} | ${'bucketName'}
      ${'path style'}    | ${findPathStyle}       | ${'change'} | ${false}          | ${'pathStyle'}
    `(
      'when $field changes the entire config object with only $field changed',
      ({ findField, event, eventPayload, key }) => {
        findField().vm.$emit(event, eventPayload);

        expect(wrapper.emitted('input')).toEqual([[{ ...mockValue, [key]: eventPayload }]]);
      },
    );

    it('a copy of config object when a field changes and leaves value prop unchanged', () => {
      findAccessKeyId().vm.$emit('input', 'NEWKEY');

      expect(wrapper.emitted('input')[0][0]).not.toBe(mockValue);
      expect(mockValue.accessKeyId).toBe('AKIAEXAMPLE');
    });
  });

  describe('when validation is attempted', () => {
    it('and form is invalid triggers an error state on required fields', () => {
      createComponent({ props: { validationAttempted: true }, mountFn: mountExtended });

      expect(findAccessKeyId().attributes('aria-invalid')).toBe('true');
      expect(findSecretAccessKey().find('input').attributes('aria-invalid')).toBe('true');
      expect(findRegion().attributes('aria-invalid')).toBe('true');
      expect(findBucketName().attributes('aria-invalid')).toBe('true');
    });

    it('and form is valid does not trigger error on required fields', () => {
      createComponent({
        props: { value: mockValue, validationAttempted: true },
        mountFn: mountExtended,
      });

      expect(findAccessKeyId().attributes('aria-invalid')).toBeUndefined();
      expect(findSecretAccessKey().find('input').attributes('aria-invalid')).toBeUndefined();
      expect(findRegion().attributes('aria-invalid')).toBeUndefined();
      expect(findBucketName().attributes('aria-invalid')).toBeUndefined();
    });
  });

  describe('when variant is export', () => {
    beforeEach(() => createComponent({ props: { variant: 'export' }, mountFn: mountExtended }));

    it('describes the bucket as a write target', () => {
      expect(findBucketNameGroup().text()).toContain(
        'The bucket where export files will be written. It must already exist and allow write access.',
      );
    });

    it('names the secret access key input for the export form', () => {
      expect(findSecretAccessKey().props('name')).toBe('offline_export_secret_access_key');
    });
  });

  describe('when variant is import', () => {
    beforeEach(() => createComponent({ props: { variant: 'import' }, mountFn: mountExtended }));

    it('describes the bucket as a read source', () => {
      expect(findBucketNameGroup().text()).toContain(
        'The bucket the export package was written to. It must already exist and allow read access.',
      );
    });

    it('names the secret access key input as import form', () => {
      expect(findSecretAccessKey().props('name')).toBe('offline_import_secret_access_key');
    });
  });

  describe('when variant is unknown', () => {
    it('rejects unknown variant', () => {
      expect(() => assertProps(ObjectStorageFields, { variant: 'archive' })).toThrow();
    });
  });

  it.each([
    ['Access key ID', 'export', 'offline-export-access-key-id'],
    ['Secret access key', 'export', 'offline-export-secret-access-key'],
    ['Region', 'export', 'offline-export-region'],
    ['Bucket name', 'export', 'offline-export-bucket-name'],
    ['Access key ID', 'import', 'offline-import-access-key-id'],
    ['Secret access key', 'import', 'offline-import-secret-access-key'],
    ['Region', 'import', 'offline-import-region'],
    ['Bucket name', 'import', 'offline-import-bucket-name'],
  ])('links the %s label in the %s form to #%s', (label, variant, id) => {
    createComponent({ props: { variant }, mountFn: mountExtended });

    expect(wrapper.findByLabelText(label).attributes('id')).toBe(id);
  });

  describe('additional-fields slot', () => {
    it('renders slot content', () => {
      createComponent({
        mountFn: mountExtended,
        slots: { 'additional-fields': '<div data-testid="extra-field">Export prefix</div>' },
      });

      expect(wrapper.findByTestId('extra-field').exists()).toBe(true);
    });

    it('renders nothing when no slot content is given', () => {
      createComponent({ mountFn: mountExtended });

      expect(wrapper.findByTestId('extra-field').exists()).toBe(false);
    });
  });
});
