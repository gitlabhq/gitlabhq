<script>
import { GlModal, GlDisclosureDropdownItem, GlModalDirective } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';

export default {
  components: {
    GlModal,
    GlDisclosureDropdownItem,
  },
  directives: {
    GlModalDirective,
  },
  inject: ['versionName'],
  data() {
    return {
      isDeleteModalVisible: false,
    };
  },
  computed: {
    deleteConfirmationText() {
      return sprintf(
        s__('MlModelRegistry|Are you sure you want to delete model version %{versionName}?'),
        {
          versionName: this.versionName,
        },
      );
    },
  },
  methods: {
    deleteModelVersion() {
      this.$emit('delete-model-version');
    },
  },
  modal: {
    id: 'ml-model-version-delete-modal',
    actionPrimary: {
      text: s__('MlModelRegistry|Delete model version'),
      attributes: { variant: 'danger' },
    },
    actionCancel: {
      text: __('Cancel'),
    },
  },
  i18n: {
    modalTitle: s__('MlModelRegistry|Delete model version?'),
  },
};
</script>

<template>
  <gl-disclosure-dropdown-item
    v-gl-modal-directive="$options.modal.id"
    :aria-label="$options.modal.actionPrimary.text"
    variant="danger"
  >
    <template #list-item>
      <span class="gl-text-red-500" data-testid="menu-item-text">
        {{ $options.modal.actionPrimary.text }}
      </span>

      <gl-modal
        :modal-id="$options.modal.id"
        :title="$options.i18n.modalTitle"
        :action-primary="$options.modal.actionPrimary"
        :action-cancel="$options.modal.actionCancel"
        @primary="deleteModelVersion"
      >
        <p>
          {{ deleteConfirmationText }}
        </p>
      </gl-modal>
    </template>
  </gl-disclosure-dropdown-item>
</template>
