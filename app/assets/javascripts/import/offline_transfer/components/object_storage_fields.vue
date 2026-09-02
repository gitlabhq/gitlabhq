<script>
import { GlFormGroup, GlFormInput, GlFormCheckbox } from '@gitlab/ui';
import PasswordInput from '~/authentication/password/components/password_input.vue';
import { s__ } from '~/locale';
import { OBJECT_STORAGE_VARIANT_EXPORT, OBJECT_STORAGE_VARIANT_IMPORT } from '../constants';
import { getStorageConfigErrors } from '../storage_config_validation';

export default {
  name: 'ObjectStorageFields',
  components: {
    GlFormGroup,
    GlFormInput,
    GlFormCheckbox,
    PasswordInput,
  },
  props: {
    variant: {
      type: String,
      required: true,
      validator: (value) =>
        [OBJECT_STORAGE_VARIANT_EXPORT, OBJECT_STORAGE_VARIANT_IMPORT].includes(value),
    },
    value: {
      type: Object,
      required: false,
      default: () => ({
        accessKeyId: '',
        secretAccessKey: '',
        region: '',
        bucketName: '',
        pathStyle: false,
      }),
    },
    validationAttempted: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['input'],
  computed: {
    errors() {
      return getStorageConfigErrors(this.value);
    },
    bucketDescription() {
      return this.$options.bucketDescriptions[this.variant];
    },
    secretAccessKeyName() {
      return `offline_${this.variant}_secret_access_key`;
    },
  },
  methods: {
    updateField(field, fieldValue) {
      this.$emit('input', { ...this.value, [field]: fieldValue });
    },
    fieldState(field) {
      return this.validationAttempted && this.errors[field] ? false : null;
    },
    setFieldId(field) {
      return `offline-${this.variant}-${field}`;
    },
  },
  bucketDescriptions: {
    [OBJECT_STORAGE_VARIANT_EXPORT]: s__(
      'OfflineTransfer|The bucket where export files will be written. It must already exist and allow write access.',
    ),
    [OBJECT_STORAGE_VARIANT_IMPORT]: s__(
      'OfflineTransfer|The bucket the export package was written to. It must already exist and allow read access.',
    ),
  },
  placeholders: {
    region: 'us-east-1',
  },
};
</script>

<template>
  <div>
    <gl-form-group
      :label="s__('OfflineTransfer|Access key ID')"
      :description="
        s__(
          'OfflineTransfer|Your object storage access key. For AWS S3, find this in your IAM security credentials.',
        )
      "
      :state="fieldState('accessKeyId')"
      :invalid-feedback="errors.accessKeyId"
      :label-for="setFieldId('access-key-id')"
    >
      <gl-form-input
        :id="setFieldId('access-key-id')"
        :value="value.accessKeyId"
        :state="fieldState('accessKeyId')"
        autocomplete="off"
        data-testid="access-key-id-input"
        @input="updateField('accessKeyId', $event)"
      />
    </gl-form-group>

    <gl-form-group
      :label="s__('OfflineTransfer|Secret access key')"
      :description="s__('OfflineTransfer|Your object storage secret key.')"
      :state="fieldState('secretAccessKey')"
      :invalid-feedback="errors.secretAccessKey"
      :label-for="setFieldId('secret-access-key')"
    >
      <password-input
        :id="setFieldId('secret-access-key')"
        :name="secretAccessKeyName"
        :value="value.secretAccessKey"
        :required="false"
        :state="fieldState('secretAccessKey')"
        autocomplete="new-password"
        testid="secret-access-key-input"
        @input="updateField('secretAccessKey', $event)"
      />
    </gl-form-group>

    <gl-form-group
      :label="s__('OfflineTransfer|Region')"
      :description="s__('OfflineTransfer|The AWS region where your bucket is located.')"
      :state="fieldState('region')"
      :invalid-feedback="errors.region"
      :label-for="setFieldId('region')"
    >
      <gl-form-input
        :id="setFieldId('region')"
        :value="value.region"
        :placeholder="$options.placeholders.region"
        :state="fieldState('region')"
        autocomplete="off"
        data-testid="region-input"
        @input="updateField('region', $event)"
      />
    </gl-form-group>

    <gl-form-group
      :label="s__('OfflineTransfer|Bucket name')"
      :description="bucketDescription"
      :state="fieldState('bucketName')"
      :invalid-feedback="errors.bucketName"
      :label-for="setFieldId('bucket-name')"
      data-testid="bucket-name-group"
    >
      <gl-form-input
        :id="setFieldId('bucket-name')"
        :value="value.bucketName"
        :state="fieldState('bucketName')"
        autocomplete="off"
        data-testid="bucket-name-input"
        @input="updateField('bucketName', $event)"
      />
    </gl-form-group>

    <slot name="additional-fields"></slot>

    <gl-form-group>
      <gl-form-checkbox
        :checked="value.pathStyle"
        data-testid="path-style-checkbox"
        @change="updateField('pathStyle', $event)"
      >
        {{ s__('OfflineTransfer|Use path-style URLs (optional)') }}
        <template #help>{{
          s__(
            'OfflineTransfer|Connect using path-style bucket URLs instead of the default virtual-hosted style. Most AWS S3 buckets use the default, so leave this unchecked unless your setup requires it.',
          )
        }}</template>
      </gl-form-checkbox>
    </gl-form-group>
  </div>
</template>
