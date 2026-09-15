<script>
import { GlFormGroup, GlFormInput } from '@gitlab/ui';

import ObjectStorageFields from '../components/object_storage_fields.vue';
import { getExportPrefixError } from '../storage_config_validation';
import { OBJECT_STORAGE_VARIANT_IMPORT } from '../constants';

export default {
  name: 'ImportConfigTab',
  components: {
    GlFormGroup,
    GlFormInput,
    ObjectStorageFields,
  },
  props: {
    storageConfig: {
      type: Object,
      required: true,
    },
    validationAttempted: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['storage-input'],
  computed: {
    exportPrefixError() {
      return getExportPrefixError(this.storageConfig.exportPrefix);
    },
    exportPrefixState() {
      return this.validationAttempted && this.exportPrefixError ? false : null;
    },
  },
  methods: {
    updateExportPrefix(value) {
      this.$emit('storage-input', { ...this.storageConfig, exportPrefix: value });
    },
  },
  OBJECT_STORAGE_VARIANT_IMPORT,
};
</script>

<template>
  <div class="gl-max-w-2xl">
    <h2 class="gl-heading-2 gl-mb-2">
      {{ s__('OfflineTransferImport|Enter AWS credentials') }}
    </h2>
    <p class="gl-my-4">
      {{
        s__(
          'OfflineTransferImport|These credentials are used to read the export package to be imported. The credentials are not used to browse or write to your storage.',
        )
      }}
    </p>

    <object-storage-fields
      :variant="$options.OBJECT_STORAGE_VARIANT_IMPORT"
      :value="storageConfig"
      :validation-attempted="validationAttempted"
      @input="$emit('storage-input', $event)"
    >
      <template #additional-fields>
        <gl-form-group
          :label="s__('OfflineTransferImport|Export prefix')"
          :description="
            s__(
              'OfflineTransferImport|The export prefix was provided in an email from GitLab after your offline export completed.',
            )
          "
          :state="exportPrefixState"
          :invalid-feedback="exportPrefixError"
          label-for="offline-import-export-prefix"
          data-testid="export-prefix-group"
        >
          <gl-form-input
            id="offline-import-export-prefix"
            :value="storageConfig.exportPrefix"
            :state="exportPrefixState"
            autocomplete="off"
            data-testid="export-prefix-input"
            @input="updateExportPrefix"
          />
        </gl-form-group>
      </template>
    </object-storage-fields>
  </div>
</template>
