<script>
import { GlIcon, GlTooltipDirective, GlOutsideDirective as Outside } from '@gitlab/ui';
import { mapGetters, mapActions } from 'vuex';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';
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
    iconClass: 'is-active',
    displayText: __('Locked'),
  },
  unlocked: {
    class: ['no-value hide-collapsed'],
    icon: 'lock-open',
    iconClass: '',
    displayText: __('Unlocked'),
  },
  components: {
    EditForm,
    GlIcon,
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
  data() {
    return {
      isLockDialogOpen: false,
    };
  },
  computed: {
    ...mapGetters(['getNoteableData']),
    isMergeRequest() {
      return (
        this.getNoteableData.targetType === TYPE_MERGE_REQUEST && this.glFeatures.movedMrSidebar
      );
    },
    issuableDisplayName() {
      const isInIssuePage = this.getNoteableData.targetType === TYPE_ISSUE;
      return isInIssuePage ? __('issue') : __('merge request');
    },
    isLocked() {
      return this.getNoteableData.discussion_locked;
    },
    lockStatus() {
      return this.isLocked ? this.$options.locked : this.$options.unlocked;
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
          if (this.isMergeRequest) {
            toast(this.isLocked ? __('Merge request locked.') : __('Merge request unlocked.'));
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
  <li v-if="isMergeRequest" class="gl-dropdown-item">
    <button type="button" class="dropdown-item" @click="toggleLocked">
      <span class="gl-dropdown-item-text-wrapper">
        <template v-if="isLocked">
          {{ __('Unlock merge request') }}
        </template>
        <template v-else>
          {{ __('Lock merge request') }}
        </template>
      </span>
    </button>
  </li>
  <div v-else class="block issuable-sidebar-item lock">
    <div
      v-gl-tooltip.left.viewport="{ title: tooltipLabel }"
      class="sidebar-collapsed-icon"
      data-testid="sidebar-collapse-icon"
      @click="toggleForm"
    >
      <gl-icon :name="lockStatus.icon" class="sidebar-item-icon is-active" />
    </div>

    <div class="hide-collapsed gl-line-height-20 gl-mb-2 gl-text-gray-900 gl-font-weight-bold">
      {{ sprintf(__('Lock %{issuableDisplayName}'), { issuableDisplayName: issuableDisplayName }) }}
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
