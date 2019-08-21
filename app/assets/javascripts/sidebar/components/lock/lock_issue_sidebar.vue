<script>
import { __, sprintf } from '~/locale';
import Flash from '~/flash';
import tooltip from '~/vue_shared/directives/tooltip';
import issuableMixin from '~/vue_shared/mixins/issuable';
import Icon from '~/vue_shared/components/icon.vue';
import eventHub from '~/sidebar/event_hub';
import editForm from './edit_form.vue';
import { trackEvent } from 'ee_else_ce/event_tracking/issue_sidebar';

export default {
  components: {
    editForm,
    Icon,
  },

  directives: {
    tooltip,
  },

  mixins: [issuableMixin],

  props: {
    isLocked: {
      required: true,
      type: Boolean,
    },

    isEditable: {
      required: true,
      type: Boolean,
    },

    mediator: {
      required: true,
      type: Object,
      validator(mediatorObject) {
        return mediatorObject.service && mediatorObject.service.update && mediatorObject.store;
      },
    },
  },

  computed: {
    lockIcon() {
      return this.isLocked ? 'lock' : 'lock-open';
    },

    isLockDialogOpen() {
      return this.mediator.store.isLockDialogOpen;
    },

    tooltipLabel() {
      return this.isLocked ? __('Locked') : __('Unlocked');
    },
  },

  created() {
    eventHub.$on('closeLockForm', this.toggleForm);
  },

  beforeDestroy() {
    eventHub.$off('closeLockForm', this.toggleForm);
  },

  methods: {
    toggleForm() {
      this.mediator.store.isLockDialogOpen = !this.mediator.store.isLockDialogOpen;
    },
    onEditClick() {
      this.toggleForm();

      trackEvent('click_edit_button', 'lock_issue');
    },
    updateLockedAttribute(locked) {
      this.mediator.service
        .update(this.issuableType, {
          discussion_locked: locked,
        })
        .then(() => window.location.reload())
        .catch(() =>
          Flash(
            sprintf(
              __(
                'Something went wrong trying to change the locked state of this %{issuableDisplayName}',
              ),
              {
                issuableDisplayName: this.issuableDisplayName,
              },
            ),
          ),
        );
    },
  },
};
</script>

<template>
  <div class="block issuable-sidebar-item lock">
    <div
      v-tooltip
      :title="tooltipLabel"
      class="sidebar-collapsed-icon"
      data-container="body"
      data-placement="left"
      data-boundary="viewport"
      @click="toggleForm"
    >
      <icon :name="lockIcon" class="sidebar-item-icon is-active" />
    </div>

    <div class="title hide-collapsed">
      {{ sprintf(__('Lock %{issuableDisplayName}'), { issuableDisplayName: issuableDisplayName }) }}
      <button
        v-if="isEditable"
        class="float-right lock-edit"
        type="button"
        @click.prevent="onEditClick"
      >
        {{ __('Edit') }}
      </button>
    </div>

    <div class="value sidebar-item-value hide-collapsed">
      <edit-form
        v-if="isLockDialogOpen"
        :is-locked="isLocked"
        :update-locked-attribute="updateLockedAttribute"
        :issuable-type="issuableType"
      />

      <div v-if="isLocked" class="value sidebar-item-value">
        <icon :size="16" name="lock" class="sidebar-item-icon inline is-active" />
        {{ __('Locked') }}
      </div>

      <div v-else class="no-value sidebar-item-value hide-collapsed">
        <icon :size="16" name="lock-open" class="sidebar-item-icon inline" /> {{ __('Unlocked') }}
      </div>
    </div>
  </div>
</template>
