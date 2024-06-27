<script>
import {
  GlModal,
  GlDisclosureDropdown,
  GlTooltipDirective,
  GlDisclosureDropdownItem,
  GlModalDirective,
} from '@gitlab/ui';
import { __ } from '~/locale';
import csrf from '~/lib/utils/csrf';

export default {
  components: {
    GlModal,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModalDirective,
  },
  props: {
    deletePath: {
      type: String,
      required: true,
    },
    deleteConfirmationText: {
      type: String,
      required: true,
    },
    actionPrimaryText: {
      type: String,
      required: true,
    },
    modalTitle: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isDeleteModalVisible: false,
      modal: {
        id: 'ml-experiments-delete-modal',
        deleteConfirmation: this.deleteConfirmationText,
        actionPrimary: {
          text: this.actionPrimaryText,
          attributes: { variant: 'danger' },
        },
        actionCancel: {
          text: __('Cancel'),
        },
      },
    };
  },
  methods: {
    confirmDelete() {
      this.$refs.deleteForm.submit();
    },
  },
  csrf,
};
</script>

<template>
  <div>
    <gl-disclosure-dropdown
      placement="bottom-end"
      category="tertiary"
      :aria-label="__('More actions')"
      icon="ellipsis_v"
      no-caret
    >
      <gl-disclosure-dropdown-item
        v-gl-modal-directive="modal.id"
        :aria-label="actionPrimaryText"
        variant="danger"
      >
        <template #list-item>
          <span class="gl-text-red-500">
            {{ actionPrimaryText }}
          </span>
        </template>
      </gl-disclosure-dropdown-item>
    </gl-disclosure-dropdown>

    <form ref="deleteForm" method="post" :action="deletePath">
      <input type="hidden" name="_method" value="delete" />
      <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
    </form>

    <gl-modal
      :modal-id="modal.id"
      :title="modalTitle"
      :action-primary="modal.actionPrimary"
      :action-cancel="modal.actionCancel"
      @primary="confirmDelete"
    >
      <p>
        {{ deleteConfirmationText }}
      </p>
    </gl-modal>
  </div>
</template>
