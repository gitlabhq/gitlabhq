<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
import DeleteModelVersionDisclosureDropdownItem from './delete_model_version_disclosure_dropdown_item.vue';

export default {
  components: {
    DeleteModelVersionDisclosureDropdownItem,
    GlDisclosureDropdown,
  },
  inject: ['canWriteModelRegistry'],
  props: {
    modelVersion: {
      type: Object,
      required: true,
    },
  },
  methods: {
    deleteModelVersion(modelVersion) {
      this.$emit('delete-model-version', modelVersion);
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    placement="bottom-end"
    category="tertiary"
    :aria-label="__('More actions')"
    icon="ellipsis_v"
    no-caret
  >
    <delete-model-version-disclosure-dropdown-item
      v-if="canWriteModelRegistry"
      :model-version="modelVersion"
      @delete-model-version="deleteModelVersion"
    />
  </gl-disclosure-dropdown>
</template>
