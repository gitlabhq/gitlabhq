<script>
import { GlModal, GlSprintf, GlFormInput } from '@gitlab/ui';
import uniqueId from 'lodash/uniqueId';
import { __, s__, sprintf } from '~/locale';
import { RESOURCE_TYPES } from '~/groups_projects/constants';

export default {
  name: 'GroupsProjectsDeleteModal',
  resourceStrings: {
    [RESOURCE_TYPES.PROJECT]: {
      primaryButtonText: __('Yes, delete project'),
      cancelButtonText: __('Cancel, keep project'),
      restoreMessage: __(
        'This project can be restored until %{date}. %{linkStart}Learn more%{linkEnd}.',
      ),
    },
    [RESOURCE_TYPES.GROUP]: {
      primaryButtonText: s__('Groups|Yes, delete group'),
      cancelButtonText: s__('Groups|Cancel, keep group'),
      restoreMessage: s__(
        'Groups|This group can be restored until %{date}. %{linkStart}Learn more%{linkEnd}.',
      ),
    },
  },
  components: { GlModal, GlSprintf, GlFormInput },
  model: {
    prop: 'visible',
    event: 'change',
  },
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
    resourceType: {
      type: String,
      required: true,
      validator: (value) => Object.values(RESOURCE_TYPES).includes(value),
    },
    confirmPhrase: {
      type: String,
      required: true,
    },
    fullName: {
      type: String,
      required: true,
    },
    confirmLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    markedForDeletion: {
      type: Boolean,
      required: true,
    },
    permanentDeletionDate: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      userInput: null,
      modalId: uniqueId(`delete-modal-`),
    };
  },
  computed: {
    i18n() {
      return this.$options.resourceStrings[this.resourceType];
    },
    confirmDisabled() {
      return this.userInput !== this.confirmPhrase;
    },
    modalActionProps() {
      return {
        primary: {
          text: this.i18n.primaryButtonText,
          attributes: {
            variant: 'danger',
            disabled: this.confirmDisabled,
            loading: this.confirmLoading,
            'data-testid': 'confirm-delete-button',
          },
        },
        cancel: {
          text: this.i18n.cancelButtonText,
        },
      };
    },
    ariaLabel() {
      return sprintf(__('Delete %{name}'), {
        name: this.fullName,
      });
    },
    showRestoreMessage() {
      return !this.markedForDeletion;
    },
  },
  watch: {
    confirmLoading(isLoading, wasLoading) {
      // If the button was loading and now no longer is
      if (!isLoading && wasLoading) {
        // Hide the modal
        this.$emit('change', false);
      }
    },
  },
};
</script>

<template>
  <gl-modal
    :visible="visible"
    :modal-id="modalId"
    :action-primary="modalActionProps.primary"
    :action-cancel="modalActionProps.cancel"
    :aria-label="ariaLabel"
    @primary.prevent="$emit('primary')"
    @change="$emit('change', $event)"
  >
    <template #modal-title>{{ __('Are you absolutely sure?') }}</template>
    <div>
      <slot name="alert"></slot>
      <p class="gl-mb-1">{{ __('Enter the following to confirm:') }}</p>
      <p>
        <code class="gl-whitespace-pre-wrap">{{ confirmPhrase }}</code>
      </p>

      <gl-form-input
        id="confirm_name_input"
        v-model="userInput"
        name="confirm_name_input"
        type="text"
        data-testid="confirm-name-field"
      />
      <p
        v-if="showRestoreMessage"
        class="gl-mb-0 gl-mt-3 gl-text-subtle"
        data-testid="restore-message"
      >
        <gl-sprintf :message="i18n.restoreMessage">
          <template #date>{{ permanentDeletionDate }}</template>
          <template #link="{ content }">
            <slot name="restore-help-page-link" :content="content"></slot>
          </template>
        </gl-sprintf>
      </p>
    </div>
  </gl-modal>
</template>
