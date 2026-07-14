<script>
import { GlFormGroup, GlFormInput, GlFormCheckbox } from '@gitlab/ui';
import PasswordInput from '~/authentication/password/components/password_input.vue';
import { getStorageConfigErrors } from './storage_config_validation';

export default {
  name: 'ExportConfigTab',
  components: {
    GlFormGroup,
    GlFormInput,
    GlFormCheckbox,
    PasswordInput,
  },
  props: {
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
  },
  methods: {
    updateField(field, fieldValue) {
      this.$emit('input', { ...this.value, [field]: fieldValue });
    },
    fieldState(field) {
      return this.validationAttempted && this.errors[field] ? false : null;
    },
  },
  placeholders: {
    region: 'us-east-1',
  },
};
</script>

<template>
  <div class="gl-max-w-xl">
    <gl-form-group
      :label="s__('OfflineTransferExport|Access key ID')"
      :description="
        s__(
          'OfflineTransferExport|Your object storage access key. For AWS S3, find this in your IAM security credentials.',
        )
      "
      :state="fieldState('accessKeyId')"
      :invalid-feedback="errors.accessKeyId"
      label-for="offline-export-access-key-id"
    >
      <gl-form-input
        id="offline-export-access-key-id"
        :value="value.accessKeyId"
        :state="fieldState('accessKeyId')"
        autocomplete="off"
        data-testid="access-key-id-input"
        @input="updateField('accessKeyId', $event)"
      />
    </gl-form-group>

    <gl-form-group
      :label="s__('OfflineTransferExport|Secret access key')"
      :description="s__('OfflineTransferExport|Your object storage secret key.')"
      :state="fieldState('secretAccessKey')"
      :invalid-feedback="errors.secretAccessKey"
      label-for="offline-export-secret-access-key"
    >
      <password-input
        id="offline-export-secret-access-key"
        name="offline_export_secret_access_key"
        :value="value.secretAccessKey"
        :required="false"
        :state="fieldState('secretAccessKey')"
        autocomplete="new-password"
        testid="secret-access-key-input"
        @input="updateField('secretAccessKey', $event)"
      />
    </gl-form-group>

    <gl-form-group
      :label="s__('OfflineTransferExport|Region')"
      :description="s__('OfflineTransferExport|The AWS region where your bucket is located.')"
      :state="fieldState('region')"
      :invalid-feedback="errors.region"
      label-for="offline-export-region"
    >
      <gl-form-input
        id="offline-export-region"
        :value="value.region"
        :placeholder="$options.placeholders.region"
        :state="fieldState('region')"
        autocomplete="off"
        data-testid="region-input"
        @input="updateField('region', $event)"
      />
    </gl-form-group>

    <gl-form-group
      :label="s__('OfflineTransferExport|Bucket name')"
      :description="
        s__(
          'OfflineTransferExport|The bucket where export files will be written. It must already exist and allow write access.',
        )
      "
      :state="fieldState('bucketName')"
      :invalid-feedback="errors.bucketName"
      label-for="offline-export-bucket-name"
    >
      <gl-form-input
        id="offline-export-bucket-name"
        :value="value.bucketName"
        :state="fieldState('bucketName')"
        autocomplete="off"
        data-testid="bucket-name-input"
        @input="updateField('bucketName', $event)"
      />
    </gl-form-group>

    <gl-form-group>
      <gl-form-checkbox
        :checked="value.pathStyle"
        data-testid="path-style-checkbox"
        @change="updateField('pathStyle', $event)"
      >
        {{ s__('OfflineTransferExport|Use path-style URLs (optional)') }}
        <template #help>{{
          s__(
            'OfflineTransferExport|Connect using path-style bucket URLs instead of the default virtual-hosted style. Most AWS S3 buckets use the default, so leave this unchecked unless your setup requires it.',
          )
        }}</template>
      </gl-form-checkbox>
    </gl-form-group>
  </div>
</template>
