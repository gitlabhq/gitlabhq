<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
import { s__ } from '~/locale';
import DeleteModelVersionDisclosureDropdownItem from './delete_model_version_disclosure_dropdown_item.vue';

export default {
  components: {
    DeleteModelVersionDisclosureDropdownItem,
    GlDisclosureDropdown,
  },
  inject: ['canWriteModelRegistry'],
  methods: {
    deleteModelVersion() {
      this.$emit('delete-model-version');
    },
  },
  i18n: {
    actionPrimaryText: s__('MlModelRegistry|Delete model version'),
    modalTitle: s__('MlModelRegistry|Delete model version?'),
    deleteConfirmationText: s__(
      'MlModelRegistry|Deleting this model version will delete the associated artifacts.',
    ),
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
      :action-primary-text="$options.i18n.actionPrimaryText"
      :modal-title="$options.i18n.modalTitle"
      :delete-confirmation-text="$options.i18n.deleteConfirmationText"
      @delete-model-version="deleteModelVersion"
    />
  </gl-disclosure-dropdown>
</template>
