<script>
import {
  GlIcon,
  GlLoadingIcon,
  GlDisclosureDropdownItem,
  GlTooltipDirective,
  GlOutsideDirective as Outside,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapActions } from 'vuex';
import { TYPE_ISSUE } from '~/issues/constants';
import { __, sprintf } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { createAlert } from '~/alert';
import toast from '~/vue_shared/plugins/global_toast';
import eventHub from '../../event_hub';
import EditForm from './edit_form.vue';

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
    EditForm,
    GlIcon,
    GlLoadingIcon,
    GlDisclosureDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    Outside,
  },
  mixins: [glFeatureFlagMixin()],
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
    lockingMergeRequest: __('Locking %{issuableDisplayName}'),
    unlockingMergeRequest: __('Unlocking %{issuableDisplayName}'),
    lockMergeRequest: __('Lock %{issuableDisplayName}'),
    unlockMergeRequest: __('Unlock %{issuableDisplayName}'),
    lockedMessage: __('%{issuableDisplayName} locked.'),
    unlockedMessage: __('%{issuableDisplayName} unlocked.'),
  },
  data() {
    return {
      isLoading: false,
      isLockDialogOpen: false,
    };
  },
  computed: {
    ...mapGetters(['getNoteableData']),
    isMovedMrSidebar() {
      return this.glFeatures.movedMrSidebar;
    },
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
          if (this.isMovedMrSidebar) {
            toast(this.isLocked ? this.lockedMessageText : this.unlockedMessageText);
          }
        })
        .catch(() => {
          const alertMessage = __(
            'Something went wrong trying to change the locked state of this %{issuableDisplayName}',
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
  <li v-if="isMovedMrSidebar && isIssuable" class="gl-dropdown-item">
    <button type="button" class="dropdown-item" data-testid="issuable-lock" @click="toggleLocked">
      <span class="gl-dropdown-item-text-wrapper">
        <template v-if="isLoading">
          <gl-loading-icon inline size="sm" /> {{ lockToggleInProgressText }}
        </template>
        <template v-else>
          {{ lockToggleText }}
        </template>
      </span>
    </button>
  </li>
  <gl-disclosure-dropdown-item v-else-if="isMovedMrSidebar">
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
  <div v-else class="block issuable-sidebar-item lock">
    <div
      v-gl-tooltip.left.viewport="{ title: lockStatus.displayText }"
      class="sidebar-collapsed-icon"
      data-testid="sidebar-collapse-icon"
      @click="toggleForm"
    >
      <gl-icon :name="lockStatus.icon" class="sidebar-item-icon is-active" />
    </div>

    <div class="hide-collapsed gl-line-height-20 gl-mb-2 gl-text-gray-900 gl-font-weight-bold">
      {{ lockMergeRequestText }}
      <a
        v-if="isEditable"
        class="float-right lock-edit btn gl-text-gray-900! gl-ml-auto hide-collapsed btn-default btn-sm gl-button btn-default-tertiary gl-mr-n2"
        href="#"
        data-testid="edit-link"
        data-track-action="click_edit_button"
        data-track-label="right_sidebar"
        data-track-property="lock_issue"
        @click.prevent="toggleForm"
      >
        {{ __('Edit') }}
      </a>
    </div>

    <div class="value sidebar-item-value hide-collapsed">
      <edit-form
        v-if="isLockDialogOpen"
        v-outside="closeForm"
        data-testid="edit-form"
        :is-locked="isLocked"
        :issuable-display-name="issuableDisplayName"
      />

      <div data-testid="lock-status" class="sidebar-item-value" :class="lockStatus.class">
        {{ lockStatus.displayText }}
      </div>
    </div>
  </div>
</template>
