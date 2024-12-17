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
  props: {
    modelVersion: {
      type: Object,
      required: true,
    },
  },
  computed: {
    versionName() {
      return this.modelVersion.version;
    },
    modalId() {
      return `ml-model-version-delete-modal-${this.modelVersion.id}`;
    },
    modalTitle() {
      return sprintf(s__('MlModelRegistry|Delete version %{versionName}'), {
        versionName: this.versionName,
      });
    },
  },
  methods: {
    deleteModelVersion() {
      this.$emit('delete-model-version', this.modelVersion.id);
    },
  },
  modal: {
    actionPrimary: {
      text: s__('MlModelRegistry|Delete version'),
      attributes: { variant: 'danger' },
    },
    actionCancel: {
      text: __('Cancel'),
    },
  },
  i18n: {
    deleteConfirmationText: s__(
      'MlModelRegistry|Are you sure you want to delete this model version?',
    ),
    deleteConfirmationNote: s__(
      'MlModelRegistry|Deleting this version also deletes all of its imported or uploaded artifacts and its settings.',
    ),
  },
};
</script>

<template>
  <gl-disclosure-dropdown-item
    v-gl-modal-directive="modalId"
    :aria-label="$options.modal.actionPrimary.text"
    variant="danger"
  >
    <template #list-item>
      <span class="gl-text-danger" data-testid="menu-item-text">
        {{ $options.modal.actionPrimary.text }}
      </span>

      <gl-modal
        :modal-id="modalId"
        :title="modalTitle"
        :action-primary="$options.modal.actionPrimary"
        :action-cancel="$options.modal.actionCancel"
        @primary="deleteModelVersion"
      >
        <p>
          {{ $options.i18n.deleteConfirmationText }}
        </p>
        <p>
          <b>{{ __('Note:') }}</b>
          {{ $options.i18n.deleteConfirmationNote }}
        </p>
      </gl-modal>
    </template>
  </gl-disclosure-dropdown-item>
</template>
