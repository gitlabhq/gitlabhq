<script>
import { GlModal, GlSprintf, GlFormInput } from '@gitlab/ui';
import uniqueId from 'lodash/uniqueId';
import { __, s__, sprintf } from '~/locale';
import { RESOURCE_TYPES } from '~/groups_projects/constants';
import { getDayDifference, newDate, getCurrentUtcDate } from '~/lib/utils/datetime_utility';

export default {
  name: 'GroupsProjectsDeleteModal',
  resourceStrings: {
    [RESOURCE_TYPES.PROJECT]: {
      primaryButtonText: __('Yes, delete project'),
      cancelButtonText: __('Cancel, keep project'),
      messageDeleteDelayed: s__(
        'Projects|This action will place this project, including all its resources, in a pending deletion state for %{delayedDeletionPeriodInDays} days, and delete it permanently on %{date}.',
      ),
      messageDeletePermanently: s__(
        'Projects|This project is scheduled for deletion on %{date}. This action will permanently delete this project, including all its resources, %{strongStart}immediately%{strongEnd}. This action cannot be undone.',
      ),
    },
    [RESOURCE_TYPES.GROUP]: {
      primaryButtonText: s__('Groups|Yes, delete group'),
      cancelButtonText: s__('Groups|Cancel, keep group'),
      messageDeleteDelayed: s__(
        'Groups|This action will place this group, including its subgroups and projects, in a pending deletion state for %{delayedDeletionPeriodInDays} days, and delete it permanently on %{date}.',
      ),
      messageDeletePermanently: s__(
        'Groups|This group is scheduled for deletion on %{date}. This action will permanently delete this group, including its subgroups and projects, %{strongStart}immediately%{strongEnd}. This action cannot be undone.',
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
    modalBodyMessage() {
      if (this.markedForDeletion) {
        return this.i18n.messageDeletePermanently;
      }

      return this.i18n.messageDeleteDelayed;
    },
    delayedDeletionPeriodInDays() {
      if (this.markedForDeletion) {
        return null;
      }

      return getDayDifference(getCurrentUtcDate(), newDate(this.permanentDeletionDate));
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
      <p data-testid="modal-body-message">
        <gl-sprintf :message="modalBodyMessage">
          <template #delayedDeletionPeriodInDays>{{ delayedDeletionPeriodInDays }}</template>
          <template #date>
            <span class="gl-font-bold">{{ permanentDeletionDate }}</span>
          </template>
          <template #strong="{ content }">
            <span class="gl-font-bold">{{ content }}</span>
          </template>
        </gl-sprintf>
      </p>
      <p>
        {{
          __(
            'This action can lead to data loss. To prevent accidental actions we ask you to confirm your intention.',
          )
        }}
      </p>
      <p class="gl-mb-1 gl-font-bold">{{ __('Enter the following to confirm:') }}</p>
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
    </div>
  </gl-modal>
</template>
