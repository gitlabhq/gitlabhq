<script>
import {
  GlLoadingIcon,
  GlButton,
  GlIcon,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
  GlTooltipDirective,
} from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import { __, s__ } from '~/locale';
import api from '~/api';
import axios from '~/lib/utils/axios_utils';
import { createAlert } from '~/alert';
import MergeRequest from '~/merge_request';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import SidebarSubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import { TYPE_MERGE_REQUEST } from '~/issues/constants';

Vue.use(VueApollo);

export default {
  apolloProvider,
  i18n: {
    edit: __('Edit'),
    copyReferenceText: __('Copy reference'),
    errorMessage: __('Something went wrong. Please try again.'),
    issuableName: __('merge request'),
    reportAbuse: __('Report abuse'),
    markAsReady: __('Mark as ready'),
    markAsDraft: __('Mark as draft'),
    close: __('Close %{issuableType}'),
    closing: __('Closing %{issuableType}...'),
    reopen: __('Reopen %{issuableType}'),
    reopening: __('Reopening %{issuableType}...'),
    lock: __('Lock %{issuableType}'),
    mergeRequestActions: __('Merge request actions'),
  },
  components: {
    GlLoadingIcon,
    GlButton,
    GlIcon,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlDisclosureDropdownGroup,
    SidebarSubscriptionsWidget,
    AbuseCategorySelector,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin()],
  inject: {
    reportAbusePath: {
      default: '',
    },
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
    projectPath: {
      type: String,
      default: '',
      required: false,
    },
    url: {
      type: String,
      default: '',
      required: false,
    },
    editUrl: {
      type: String,
      default: '',
      required: false,
    },
    isCurrentUser: {
      type: Boolean,
      default: false,
      required: true,
    },
    isLoggedIn: {
      type: Boolean,
      defauilt: false,
      required: false,
    },
    canUpdateMergeRequest: {
      type: Boolean,
      default: false,
      required: false,
    },
    open: {
      type: Boolean,
      default: false,
      required: false,
    },
    isMerged: {
      type: Boolean,
      default: false,
      required: false,
    },
    sourceProjectMissing: {
      type: Boolean,
      default: false,
      required: false,
    },
    clipboardText: {
      type: String,
      default: '',
      required: false,
    },
    reportedUserId: {
      type: Number,
      default: 0,
      required: false,
    },
  },
  data() {
    return {
      isOpen: this.open,
      draft: this.mr.draft,
      issuableType: TYPE_MERGE_REQUEST,
      fullPath: this.projectPath,
      isLoading: false,
      isLoadingDraft: false,
      isLoadingClipboard: false,
      isReportAbuseDrawerOpen: false,
      isDropdownVisible: false,
    };
  },
  computed: {
    isNotificationsTodosButtons() {
      return this.glFeatures.notificationsTodosButtons;
    },
    draftLabel() {
      return this.draft ? this.$options.i18n.markAsReady : this.$options.i18n.markAsDraft;
    },
    draftState() {
      return this.draft ? 'ready' : 'draft';
    },
    editItem() {
      return {
        text: this.$options.i18n.edit,
        href: this.editUrl,
      };
    },
    showDropdownTooltip() {
      return !this.isDropdownVisible ? this.$options.i18n.mergeRequestActions : '';
    },
  },
  methods: {
    draftAction() {
      this.isLoadingDraft = true;

      axios
        .put(`${this.url}?merge_request[wip_event]=${this.draftState}`, null, {
          params: { format: 'json' },
        })
        .then(({ data }) => {
          MergeRequest.toggleDraftStatus(data.title, this.draft);
        })
        .catch(() => {
          createAlert({
            message: this.$options.i18n.errorMessage,
          });
        })
        .finally(() => {
          this.draft = !this.draft;
          this.isLoadingDraft = false;
          this.closeActionsDropdown();
        });
    },
    stateAction(state) {
      this.isLoading = true;

      api
        .updateMergeRequest(this.mr.target_project_id, this.mr.iid, { state_event: state })
        .then(() => {
          window.location.reload();
        })
        .catch(() => {
          createAlert({
            message: this.$options.i18n.errorMessage,
          });
        })
        .finally(() => {
          this.isOpen = !this.isOpen;
          this.isLoading = false;
          this.closeActionsDropdown();
        });
    },
    copyClipboardAction() {
      this.$toast.show(s__('MergeRequests|Reference copied'));
      this.closeActionsDropdown();
    },
    reportAbuseAction(isOpen) {
      if (isOpen) {
        this.closeActionsDropdown();
      }

      this.isReportAbuseDrawerOpen = isOpen;
    },
    closeActionsDropdown() {
      this.$refs.mrMoreActionsDropdown.close();
    },
    showReopenMergeRequestOption() {
      return !this.sourceProjectMissing && !this.isOpen;
    },
    showDropdown() {
      this.isDropdownVisible = true;
    },
    hideDropdown() {
      this.isDropdownVisible = false;
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-w-full gl-justify-end" data-testid="merge-request-actions">
    <gl-disclosure-dropdown
      id="new-actions-header-dropdown"
      ref="mrMoreActionsDropdown"
      v-gl-tooltip="showDropdownTooltip"
      :title="$options.i18n.mergeRequestActions"
      data-testid="dropdown-toggle"
      placement="bottom-end"
      block
      class="gl-w-full"
      :auto-close="false"
      @shown="showDropdown"
      @hidden="hideDropdown"
    >
      <template #toggle>
        <div class="gl-mb-2 gl-min-h-7 sm:!gl-mb-0">
          <gl-button
            class="gl-new-dropdown-toggle gl-w-full sm:!gl-hidden"
            button-text-classes="gl-flex gl-justify-between gl-w-full"
            category="secondary"
            tabindex="0"
            :aria-label="$options.i18n.mergeRequestActions"
          >
            <span class="">{{ $options.i18n.mergeRequestActions }}</span>
            <gl-icon class="dropdown-chevron" name="chevron-down" />
          </gl-button>
          <gl-button
            class="gl-new-dropdown-toggle gl-new-dropdown-icon-only gl-new-dropdown-toggle-no-caret gl-hidden sm:!gl-flex"
            category="tertiary"
            icon="ellipsis_v"
            tabindex="0"
            :aria-label="$options.i18n.mergeRequestActions"
            :title="$options.i18n.mergeRequestActions"
          />
        </div>
      </template>
      <gl-disclosure-dropdown-group v-if="isLoggedIn && !isNotificationsTodosButtons">
        <sidebar-subscriptions-widget
          :iid="String(mr.iid)"
          :full-path="fullPath"
          :issuable-type="issuableType"
          data-testid="notification-toggle"
        />
      </gl-disclosure-dropdown-group>

      <gl-disclosure-dropdown-group
        bordered
        :class="{
          '!gl-mt-0 !gl-border-t-0 !gl-pt-0': !isLoggedIn || isNotificationsTodosButtons,
        }"
      >
        <gl-disclosure-dropdown-item
          v-if="canUpdateMergeRequest"
          class="sm:!gl-hidden"
          data-testid="edit-merge-request"
          :item="editItem"
        />

        <gl-disclosure-dropdown-item
          v-if="isOpen && canUpdateMergeRequest"
          data-testid="ready-and-draft-action"
          @action="draftAction"
        >
          <template #list-item>
            <gl-loading-icon v-if="isLoadingDraft" inline size="sm" />
            {{ draftLabel }}
          </template>
        </gl-disclosure-dropdown-item>

        <gl-disclosure-dropdown-item
          v-if="isOpen && canUpdateMergeRequest"
          @action="stateAction('close')"
        >
          <template #list-item>
            <template v-if="isLoading">
              <gl-loading-icon inline size="sm" />
              {{
                sprintf($options.i18n.closing, {
                  issuableType: $options.i18n.issuableName,
                })
              }}
            </template>
            <template v-else>
              {{ sprintf($options.i18n.close, { issuableType: $options.i18n.issuableName }) }}
            </template>
          </template>
        </gl-disclosure-dropdown-item>

        <gl-disclosure-dropdown-item
          v-else-if="!isMerged && showReopenMergeRequestOption && canUpdateMergeRequest"
          data-testid="reopen-merge-request"
          @action="stateAction('reopen')"
        >
          <template #list-item>
            <template v-if="isLoading">
              <gl-loading-icon inline size="sm" />
              {{
                sprintf($options.i18n.reopening, {
                  issuableType: $options.i18n.issuableName,
                })
              }}
            </template>
            <template v-else>
              {{ sprintf($options.i18n.reopen, { issuableType: $options.i18n.issuableName }) }}
            </template>
          </template>
        </gl-disclosure-dropdown-item>

        <gl-disclosure-dropdown-item
          v-if="canUpdateMergeRequest"
          data-testid="lock-merge-request"
          class="js-sidebar-lock-root"
        >
          <template #list-item>
            {{ sprintf($options.i18n.lock, { issuableType: $options.i18n.issuableName }) }}
          </template>
        </gl-disclosure-dropdown-item>

        <gl-disclosure-dropdown-item
          class="js-copy-reference"
          :data-clipboard-text="clipboardText"
          data-testid="copy-reference"
          @action="copyClipboardAction"
        >
          <template #list-item>
            {{ $options.i18n.copyReferenceText }}
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown-group>

      <gl-disclosure-dropdown-group
        v-if="!isCurrentUser"
        bordered
        :class="{ '!gl-mt-0 !gl-border-t-0 !gl-pt-0': !canUpdateMergeRequest }"
      >
        <gl-disclosure-dropdown-item
          class="js-report-abuse-dropdown-item"
          data-testid="report-abuse-option"
          @action="reportAbuseAction(true)"
        >
          <template #list-item>
            {{ $options.i18n.reportAbuse }}
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown-group>
    </gl-disclosure-dropdown>

    <abuse-category-selector
      v-if="!isCurrentUser && isReportAbuseDrawerOpen"
      :reported-user-id="reportedUserId"
      :reported-from-url="url"
      :show-drawer="isReportAbuseDrawerOpen"
      @close-drawer="reportAbuseAction(false)"
    />
  </div>
</template>
