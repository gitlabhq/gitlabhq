<script>
import {
  GlLoadingIcon,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
  GlTooltipDirective,
  GlToastMixin,
} from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import api from '~/api';
import { setCookie } from '~/lib/utils/common_utils';
import { AI_OVERVIEW_COOKIE_NAME } from '~/merge_requests/constants';
import axios from '~/lib/utils/axios_utils';
import { createAlert } from '~/alert';
import MergeRequest from '~/merge_request';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';

export default {
  name: 'MrMoreDropdown',
  i18n: {
    edit: __('Edit'),
    copyReferenceText: __('Copy reference'),
    errorMessage: __('Something went wrong. Please try again.'),
    issuableName: __('merge request'),
    reportAbuse: __('Report abuse'),
    markAsReady: __('Mark as ready'),
    markAsDraft: __('Mark as draft'),
    close: __('Close %{issuableType}'),
    closing: __('Closing %{issuableType}…'),
    reopen: __('Reopen %{issuableType}'),
    reopening: __('Reopening %{issuableType}…'),
    lock: __('Lock %{issuableType}'),
    mergeRequestActions: __('Merge request actions'),
    tryAiOverview: s__('AiOverview|Try the new overview'),
    switchToClassicOverview: s__('AiOverview|Switch to the classic overview'),
  },
  components: {
    GlLoadingIcon,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlDisclosureDropdownGroup,
    AbuseCategorySelector,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [GlToastMixin],
  props: {
    mr: {
      type: Object,
      required: true,
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
    aiOverviewAvailable: {
      type: Boolean,
      default: false,
      required: false,
    },
    aiOverviewEnabled: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  data() {
    return {
      isOpen: this.open,
      draft: this.mr.draft,
      isLoading: false,
      isLoadingDraft: false,
      isReportAbuseDrawerOpen: false,
      isDropdownVisible: false,
    };
  },
  computed: {
    draftLabel() {
      return this.draft ? this.$options.i18n.markAsReady : this.$options.i18n.markAsDraft;
    },
    draftIcon() {
      return this.draft ? 'check-circle' : 'review-list';
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
    copyReferenceItem() {
      return { text: this.$options.i18n.copyReferenceText, icon: 'copy-to-clipboard' };
    },
    reportAbuseItem() {
      return { text: this.$options.i18n.reportAbuse, icon: 'abuse' };
    },
    mergeRequestOpenItem() {
      return {
        text: sprintf(this.$options.i18n.reopen, { issuableType: this.$options.i18n.issuableName }),
        icon: 'merge-request-open',
      };
    },
    mergeRequestLockItem() {
      return {
        text: sprintf(this.$options.i18n.lock, { issuableType: this.$options.i18n.issuableName }),
        icon: 'lock',
      };
    },
    mergeRequestDraftItem() {
      return { text: this.draftLabel, icon: this.draftIcon };
    },
    mergeRequestCloseItem() {
      return {
        text: sprintf(this.$options.i18n.close, { issuableType: this.$options.i18n.issuableName }),
        icon: 'merge-request-close',
      };
    },
    showDropdownTooltip() {
      return !this.isDropdownVisible ? this.$options.i18n.mergeRequestActions : '';
    },
    aiOverviewLabel() {
      return this.aiOverviewEnabled
        ? this.$options.i18n.switchToClassicOverview
        : this.$options.i18n.tryAiOverview;
    },
    aiOverviewItem() {
      return { text: this.aiOverviewLabel, icon: 'tanuki-ai' };
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
    toggleAiOverviewAction() {
      setCookie(AI_OVERVIEW_COOKIE_NAME, String(!this.aiOverviewEnabled));
      window.location.reload();
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
  <div class="gl-self-start" data-testid="merge-request-actions">
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
      icon="ellipsis_v"
      category="tertiary"
      text-sr-only
      no-caret
      :toggle-text="$options.i18n.mergeRequestActions"
      toggle-class="gl-flex"
      @shown="showDropdown"
      @hidden="hideDropdown"
    >
      <gl-disclosure-dropdown-group>
        <gl-disclosure-dropdown-item
          v-if="canUpdateMergeRequest"
          class="@sm/panel:!gl-hidden"
          data-testid="edit-merge-request"
          :item="editItem"
          icon="pencil"
        />

        <gl-disclosure-dropdown-item
          v-if="isOpen && canUpdateMergeRequest"
          :item="mergeRequestDraftItem"
          data-testid="ready-and-draft-action"
          @action="draftAction"
        >
          <template v-if="isLoadingDraft" #list-item>
            <gl-loading-icon inline size="sm" class="gl-mr-2" />
            {{ draftLabel }}
          </template>
        </gl-disclosure-dropdown-item>

        <gl-disclosure-dropdown-item
          v-if="isOpen && canUpdateMergeRequest"
          :item="mergeRequestCloseItem"
          @action="stateAction('close')"
        >
          <template v-if="isLoading" #list-item>
            <gl-loading-icon inline size="sm" class="gl-mr-2" />
            {{
              sprintf($options.i18n.closing, {
                issuableType: $options.i18n.issuableName,
              })
            }}
          </template>
        </gl-disclosure-dropdown-item>

        <gl-disclosure-dropdown-item
          v-else-if="!isMerged && showReopenMergeRequestOption && canUpdateMergeRequest"
          :item="mergeRequestOpenItem"
          data-testid="reopen-merge-request"
          @action="stateAction('reopen')"
        >
          <template v-if="isLoading" #list-item>
            <gl-loading-icon inline size="sm" class="gl-mr-2" />
            {{
              sprintf($options.i18n.reopening, {
                issuableType: $options.i18n.issuableName,
              })
            }}
          </template>
        </gl-disclosure-dropdown-item>

        <gl-disclosure-dropdown-item
          v-if="canUpdateMergeRequest"
          :item="mergeRequestLockItem"
          data-testid="lock-merge-request"
          class="js-sidebar-lock-root"
        />

        <gl-disclosure-dropdown-item
          :item="copyReferenceItem"
          class="js-copy-reference"
          :data-clipboard-text="clipboardText"
          data-testid="copy-reference"
          @action="copyClipboardAction"
        />
      </gl-disclosure-dropdown-group>

      <gl-disclosure-dropdown-group v-if="aiOverviewAvailable" bordered>
        <gl-disclosure-dropdown-item
          :item="aiOverviewItem"
          data-testid="toggle-ai-overview"
          @action="toggleAiOverviewAction"
        />
      </gl-disclosure-dropdown-group>

      <gl-disclosure-dropdown-group
        v-if="!isCurrentUser"
        bordered
        :class="{ '!gl-mt-0 !gl-border-t-0 !gl-pt-0': !canUpdateMergeRequest }"
      >
        <gl-disclosure-dropdown-item
          :item="reportAbuseItem"
          class="js-report-abuse-dropdown-item"
          data-testid="report-abuse-option"
          @action="reportAbuseAction(true)"
        />
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
