<script>
import {
  GlLoadingIcon,
  GlDisclosureDropdownItem,
  GlTooltipDirective,
  GlOutsideDirective as Outside,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapActions } from 'vuex';
import { TYPE_ISSUE } from '~/issues/constants';
import { __, sprintf } from '~/locale';
import { createAlert } from '~/alert';
import toast from '~/vue_shared/plugins/global_toast';
import eventHub from '../../event_hub';

export default {
  locked: {
    icon: 'lock',
    class: 'value',
    displayText: __('Locked'),
  },
  unlocked: {
    class: ['no-value hide-collapsed'],
    icon: 'lock-open',
    displayText: __('Unlocked'),
  },
  components: {
    GlLoadingIcon,
    GlDisclosureDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    Outside,
  },
  inject: ['fullPath'],
  props: {
    isEditable: {
      required: true,
      type: Boolean,
    },
  },
  i18n: {
    issue: __('issue'),
    issueCapitalized: __('Issue'),
    mergeRequest: __('merge request'),
    mergeRequestCapitalized: __('Merge request'),
    lockingMergeRequest: __('Locking discussion'),
    unlockingMergeRequest: __('Unlocking discussion'),
    lockMergeRequest: __('Lock discussion'),
    unlockMergeRequest: __('Unlock discussion'),
    lockedMessage: __('Discussion locked.'),
    unlockedMessage: __('Discussion unlocked.'),
  },
  data() {
    return {
      isLoading: false,
      isLockDialogOpen: false,
    };
  },
  computed: {
    ...mapGetters(['getNoteableData']),
    isIssuable() {
      return this.getNoteableData.targetType === TYPE_ISSUE;
    },
    issuableDisplayName() {
      return this.isIssuable ? this.$options.i18n.issue : this.$options.i18n.mergeRequest;
    },
    issuableDisplayNameCapitalized() {
      return this.isIssuable
        ? this.$options.i18n.issueCapitalized
        : this.$options.i18n.mergeRequestCapitalized;
    },
    isLocked() {
      return this.getNoteableData.discussion_locked;
    },
    lockStatus() {
      return this.isLocked ? this.$options.locked : this.$options.unlocked;
    },
    lockToggleInProgressText() {
      return this.isLocked ? this.unlockingMergeRequestText : this.lockingMergeRequestText;
    },
    lockToggleText() {
      return this.isLocked ? this.unlockMergeRequestText : this.lockMergeRequestText;
    },
    lockingMergeRequestText() {
      return sprintf(this.$options.i18n.lockingMergeRequest, {
        issuableDisplayName: this.issuableDisplayName,
      });
    },
    unlockingMergeRequestText() {
      return sprintf(this.$options.i18n.unlockingMergeRequest, {
        issuableDisplayName: this.issuableDisplayName,
      });
    },
    lockMergeRequestText() {
      return sprintf(this.$options.i18n.lockMergeRequest, {
        issuableDisplayName: this.issuableDisplayName,
      });
    },
    unlockMergeRequestText() {
      return sprintf(this.$options.i18n.unlockMergeRequest, {
        issuableDisplayName: this.issuableDisplayName,
      });
    },
    lockedMessageText() {
      return sprintf(this.$options.i18n.lockedMessage, {
        issuableDisplayName: this.issuableDisplayNameCapitalized,
      });
    },
    unlockedMessageText() {
      return sprintf(this.$options.i18n.unlockedMessage, {
        issuableDisplayName: this.issuableDisplayNameCapitalized,
      });
    },
  },

  created() {
    eventHub.$on('closeLockForm', this.toggleForm);
  },

  beforeDestroy() {
    eventHub.$off('closeLockForm', this.toggleForm);
  },

  methods: {
    ...mapActions(['updateLockedAttribute']),
    toggleForm() {
      if (this.isEditable) {
        this.isLockDialogOpen = !this.isLockDialogOpen;
      }
    },
    toggleLocked() {
      this.isLoading = true;

      this.updateLockedAttribute({
        locked: !this.isLocked,
        fullPath: this.fullPath,
      })
        .then(() => {
          toast(this.isLocked ? this.lockedMessageText : this.unlockedMessageText);
        })
        .catch(() => {
          const alertMessage = __(
            'Something went wrong trying to change the locked state of the discussion',
          );
          createAlert({
            message: sprintf(alertMessage, { issuableDisplayName: this.issuableDisplayName }),
          });
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
    closeForm() {
      this.isLockDialogOpen = false;
    },
  },
};
</script>

<template>
  <li v-if="isIssuable" class="gl-new-dropdown-item">
    <button
      type="button"
      class="gl-new-dropdown-item-content"
      data-testid="issuable-lock"
      @click="toggleLocked"
    >
      <span class="gl-new-dropdown-item-text-wrapper">
        <template v-if="isLoading">
          <gl-loading-icon inline size="sm" /> {{ lockToggleInProgressText }}
        </template>
        <template v-else>
          {{ lockToggleText }}
        </template>
      </span>
    </button>
  </li>
  <gl-disclosure-dropdown-item v-else>
    <button
      type="button"
      class="gl-new-dropdown-item-content"
      data-testid="issuable-lock"
      @click="toggleLocked"
    >
      <span class="gl-new-dropdown-item-text-wrapper">
        <template v-if="isLoading">
          <gl-loading-icon inline size="sm" /> {{ lockToggleInProgressText }}
        </template>
        <template v-else>
          {{ lockToggleText }}
        </template>
      </span>
    </button>
  </gl-disclosure-dropdown-item>
</template>
