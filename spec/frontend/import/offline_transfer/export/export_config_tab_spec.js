import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import ExportConfigTab from '~/import/offline_transfer/export/export_config_tab.vue';
import PasswordInput from '~/authentication/password/components/password_input.vue';

describe('ExportConfigTab', () => {
  let wrapper;

  const mockValue = {
    accessKeyId: 'AKIAEXAMPLE',
    secretAccessKey: 'super',
    region: 'eu-west-1',
    bucketName: 'my-export-bucket',
    pathStyle: true,
  };

  const createComponent = (propsData = {}, mountFn = shallowMountExtended) => {
    wrapper = mountFn(ExportConfigTab, {
      propsData,
    });
  };

  const findAccessKeyId = () => wrapper.findByTestId('access-key-id-input');
  const findSecretAccessKey = () => wrapper.findComponent(PasswordInput);
  const findRegion = () => wrapper.findByTestId('region-input');
  const findBucketName = () => wrapper.findByTestId('bucket-name-input');
  const findPathStyle = () => wrapper.findByTestId('path-style-checkbox');

  describe('default renders', () => {
    beforeEach(() => createComponent());

    it('AWS S3 configuration controls correctly', () => {
      expect(findAccessKeyId().attributes('placeholder')).toBeUndefined();
      expect(findAccessKeyId().props('value')).toBe('');

      expect(findRegion().attributes('placeholder')).toBe('us-east-1');
      expect(findRegion().props('value')).toBe('');

      expect(findSecretAccessKey().props()).toMatchObject({
        required: false,
        autocomplete: 'new-password',
      });

      expect(findBucketName().props('value')).toBe('');

      expect(findPathStyle().props('checked')).toBe(false);
    });
  });

  describe('when a value is provided renders', () => {
    beforeEach(() => createComponent({ value: mockValue }));

    it('each text field with the correct value', () => {
      expect(findAccessKeyId().props('value')).toBe(mockValue.accessKeyId);
      expect(findSecretAccessKey().props('value')).toBe(mockValue.secretAccessKey);
      expect(findRegion().props('value')).toBe(mockValue.region);
      expect(findBucketName().props('value')).toBe(mockValue.bucketName);
    });

    it('pathStyle as checked', () => {
      expect(findPathStyle().props('checked')).toBe(true);
    });
  });

  describe('emits', () => {
    beforeEach(() => createComponent({ value: mockValue }));

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
      createComponent({ validationAttempted: true }, mountExtended);
      expect(findAccessKeyId().attributes('aria-invalid')).toBe('true');
      expect(findSecretAccessKey().find('input').attributes('aria-invalid')).toBe('true');
      expect(findRegion().attributes('aria-invalid')).toBe('true');
      expect(findBucketName().attributes('aria-invalid')).toBe('true');
    });

    it('and form is valid does not trigger error on required fields', () => {
      createComponent({ value: mockValue, validationAttempted: true }, mountExtended);
      expect(findAccessKeyId().attributes('aria-invalid')).toBeUndefined();
      expect(findSecretAccessKey().find('input').attributes('aria-invalid')).toBeUndefined();
      expect(findRegion().attributes('aria-invalid')).toBeUndefined();
      expect(findBucketName().attributes('aria-invalid')).toBeUndefined();
    });
  });
});
