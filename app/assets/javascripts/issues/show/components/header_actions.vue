<script>
import {
  GlButton,
  GlDropdown,
  GlDropdownDivider,
  GlDropdownItem,
  GlLink,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { mapActions, mapGetters, mapState } from 'vuex';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { EVENT_ISSUABLE_VUE_APP_CHANGE } from '~/issuable/constants';
import { STATUS_CLOSED, TYPE_INCIDENT, TYPE_ISSUE, IssuableTypeText } from '~/issues/constants';
import {
  ISSUE_STATE_EVENT_CLOSE,
  ISSUE_STATE_EVENT_REOPEN,
  NEW_ACTIONS_POPOVER_KEY,
} from '~/issues/show/constants';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { getCookie, parseBoolean, setCookie } from '~/lib/utils/common_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { s__, __, sprintf } from '~/locale';
import eventHub from '~/notes/event_hub';
import Tracking from '~/tracking';
import toast from '~/vue_shared/plugins/global_toast';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import NewHeaderActionsPopover from '~/issues/show/components/new_header_actions_popover.vue';
import SidebarSubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import IssuableLockForm from '~/sidebar/components/lock/issuable_lock_form.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import issueReferenceQuery from '~/sidebar/queries/issue_reference.query.graphql';
import issuesEventHub from '../event_hub';
import promoteToEpicMutation from '../queries/promote_to_epic.mutation.graphql';
import updateIssueMutation from '../queries/update_issue.mutation.graphql';
import DeleteIssueModal from './delete_issue_modal.vue';

const trackingMixin = Tracking.mixin({ label: 'delete_issue' });

export default {
  actionCancel: {
    text: __('Cancel'),
  },
  actionPrimary: {
    text: __('Yes, close issue'),
  },
  deleteModalId: 'delete-modal-id',
  i18n: {
    edit: __('Edit'),
    editTitleAndDescription: __('Edit title and description'),
    promoteErrorMessage: __(
      'Something went wrong while promoting the issue to an epic. Please try again.',
    ),
    promoteSuccessMessage: __(
      'The issue was successfully promoted to an epic. Redirecting to epic...',
    ),
    reportAbuse: __('Report abuse to administrator'),
    referenceFetchError: __('An error occurred while fetching reference'),
    copyReferenceText: __('Copy reference'),
  },
  components: {
    DeleteIssueModal,
    GlButton,
    GlDropdown,
    GlDropdownDivider,
    GlDropdownItem,
    GlLink,
    GlModal,
    AbuseCategorySelector,
    NewHeaderActionsPopover,
    SidebarSubscriptionsWidget,
    IssuableLockForm,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  mixins: [trackingMixin, glFeatureFlagMixin()],
  inject: {
    canCreateIssue: {
      default: false,
    },
    canDestroyIssue: {
      default: false,
    },
    canPromoteToEpic: {
      default: false,
    },
    canReopenIssue: {
      default: false,
    },
    canReportSpam: {
      default: false,
    },
    canUpdateIssue: {
      default: false,
    },
    iid: {
      default: '',
    },
    isIssueAuthor: {
      default: false,
    },
    issuePath: {
      default: '',
    },
    issueType: {
      default: TYPE_ISSUE,
    },
    newIssuePath: {
      default: '',
    },
    projectPath: {
      default: '',
    },
    submitAsSpamPath: {
      default: '',
    },
    reportedUserId: {
      default: '',
    },
    reportedFromUrl: {
      default: '',
    },
    issuableEmailAddress: {
      default: '',
    },
    fullPath: {
      default: '',
    },
  },
  data() {
    return {
      isReportAbuseDrawerOpen: false,
    };
  },
  apollo: {
    issuableReference: {
      query: issueReferenceQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.iid,
        };
      },
      update(data) {
        return data.workspace?.issuable?.reference || '';
      },
      skip() {
        return !this.isMrSidebarMoved;
      },
      error(error) {
        createAlert({ message: this.$options.i18n.referenceFetchError });
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    ...mapState(['isToggleStateButtonLoading']),
    ...mapGetters(['openState', 'getBlockedByIssues']),
    ...mapGetters(['getNoteableData']),
    isLocked() {
      return this.getNoteableData.discussion_locked;
    },
    isClosed() {
      return this.openState === STATUS_CLOSED;
    },
    issueTypeText() {
      const issueTypeTexts = {
        [TYPE_ISSUE]: s__('HeaderAction|issue'),
        [TYPE_INCIDENT]: s__('HeaderAction|incident'),
      };

      return issueTypeTexts[this.issueType] ?? this.issueType;
    },
    buttonText() {
      return this.isClosed
        ? sprintf(__('Reopen %{issueType}'), { issueType: this.issueTypeText })
        : sprintf(__('Close %{issueType}'), { issueType: this.issueTypeText });
    },
    deleteButtonText() {
      return sprintf(__('Delete %{issuableType}'), { issuableType: this.issueTypeText });
    },
    qaSelector() {
      return this.isClosed ? 'reopen_issue_button' : 'close_issue_button';
    },
    dropdownText() {
      return sprintf(__('%{issueType} actions'), {
        issueType: capitalizeFirstCharacter(this.issueType),
      });
    },
    newIssueTypeText() {
      return sprintf(__('New related %{issueType}'), { issueType: this.issueType });
    },
    showToggleIssueStateButton() {
      const canClose = !this.isClosed && this.canUpdateIssue;
      const canReopen = this.isClosed && this.canReopenIssue;
      return canClose || canReopen;
    },
    hasDesktopDropdown() {
      return (
        this.canCreateIssue || this.canPromoteToEpic || !this.isIssueAuthor || this.canReportSpam
      );
    },
    hasMobileDropdown() {
      return this.hasDesktopDropdown || this.showToggleIssueStateButton;
    },
    copyMailAddressText() {
      return sprintf(__('Copy %{issueType} email address'), {
        issueType: IssuableTypeText[this.issueType],
      });
    },
    isMrSidebarMoved() {
      return this.glFeatures.movedMrSidebar;
    },
    showLockIssueOption() {
      return this.isMrSidebarMoved && this.issueType === TYPE_ISSUE;
    },
  },
  created() {
    eventHub.$on('toggle.issuable.state', this.toggleIssueState);
  },
  beforeDestroy() {
    eventHub.$off('toggle.issuable.state', this.toggleIssueState);
  },
  methods: {
    ...mapActions(['toggleStateButtonLoading']),
    ...mapActions(['updateLockedAttribute']),
    toggleIssueState() {
      if (!this.isClosed && this.getBlockedByIssues?.length) {
        this.$refs.blockedByIssuesModal.show();
        return;
      }

      this.invokeUpdateIssueMutation();
    },
    toggleReportAbuseDrawer(isOpen) {
      this.isReportAbuseDrawerOpen = isOpen;
    },
    invokeUpdateIssueMutation() {
      this.toggleStateButtonLoading(true);

      this.$apollo
        .mutate({
          mutation: updateIssueMutation,
          variables: {
            input: {
              iid: this.iid.toString(),
              projectPath: this.projectPath,
              stateEvent: this.isClosed ? ISSUE_STATE_EVENT_REOPEN : ISSUE_STATE_EVENT_CLOSE,
            },
          },
        })
        .then(({ data }) => {
          if (data.updateIssue.errors.length) {
            throw new Error();
          }

          const payload = {
            detail: {
              data: { id: this.iid },
              isClosed: !this.isClosed,
            },
          };

          // Dispatch event which updates open/close state, shared among the issue show page
          document.dispatchEvent(new CustomEvent(EVENT_ISSUABLE_VUE_APP_CHANGE, payload));
        })
        .catch(() => createAlert({ message: __('Error occurred while updating the issue status') }))
        .finally(() => {
          this.toggleStateButtonLoading(false);
        });
    },
    promoteToEpic() {
      this.toggleStateButtonLoading(true);

      this.$apollo
        .mutate({
          mutation: promoteToEpicMutation,
          variables: {
            input: {
              iid: this.iid,
              projectPath: this.projectPath,
            },
          },
        })
        .then(({ data }) => {
          if (data.promoteToEpic.errors.length) {
            throw new Error();
          }

          createAlert({
            message: this.$options.i18n.promoteSuccessMessage,
            variant: VARIANT_SUCCESS,
          });

          visitUrl(data.promoteToEpic.epic.webPath);
        })
        .catch(() => createAlert({ message: this.$options.i18n.promoteErrorMessage }))
        .finally(() => {
          this.toggleStateButtonLoading(false);
        });
    },
    edit() {
      issuesEventHub.$emit('open.form');
    },
    dismissPopover() {
      if (this.isMrSidebarMoved && !parseBoolean(getCookie(`${NEW_ACTIONS_POPOVER_KEY}`))) {
        setCookie(NEW_ACTIONS_POPOVER_KEY, true);
      }
    },
    copyReference() {
      toast(__('Reference copied'));
    },
    copyEmailAddress() {
      toast(__('Email address copied'));
    },
  },
  TYPE_ISSUE,
};
</script>

<template>
  <div class="detail-page-header-actions gl-display-flex gl-align-self-start">
    <gl-dropdown
      v-if="hasMobileDropdown"
      class="gl-sm-display-none! w-100"
      block
      :text="dropdownText"
      data-qa-selector="issue_actions_dropdown"
      data-testid="mobile-dropdown"
      :loading="isToggleStateButtonLoading"
    >
      <template v-if="isMrSidebarMoved">
        <sidebar-subscriptions-widget
          :iid="String(iid)"
          :full-path="fullPath"
          :issuable-type="$options.TYPE_ISSUE"
          data-testid="notification-toggle"
        />

        <gl-dropdown-divider />
      </template>

      <template v-if="showLockIssueOption">
        <issuable-lock-form :is-editable="false" data-testid="lock-issue-toggle" />
      </template>

      <gl-dropdown-item v-if="canUpdateIssue" @click="edit">
        {{ $options.i18n.edit }}
      </gl-dropdown-item>
      <gl-dropdown-item
        v-if="showToggleIssueStateButton"
        :data-qa-selector="`mobile_${qaSelector}`"
        @click="toggleIssueState"
      >
        {{ buttonText }}
      </gl-dropdown-item>
      <gl-dropdown-item v-if="canCreateIssue" :href="newIssuePath">
        {{ newIssueTypeText }}
      </gl-dropdown-item>
      <gl-dropdown-item v-if="canPromoteToEpic" @click="promoteToEpic">
        {{ __('Promote to epic') }}
      </gl-dropdown-item>
      <template v-if="isMrSidebarMoved">
        <gl-dropdown-item
          :data-clipboard-text="issuableReference"
          data-testid="copy-reference"
          @click="copyReference"
          >{{ $options.i18n.copyReferenceText }}</gl-dropdown-item
        >
        <gl-dropdown-item
          v-if="issuableEmailAddress"
          :data-clipboard-text="issuableEmailAddress"
          data-testid="copy-email"
          @click="copyEmailAddress"
          >{{ copyMailAddressText }}</gl-dropdown-item
        >
      </template>
      <gl-dropdown-item
        v-if="canReportSpam"
        :href="submitAsSpamPath"
        data-method="post"
        rel="nofollow"
      >
        {{ __('Submit as spam') }}
      </gl-dropdown-item>
      <template v-if="canDestroyIssue">
        <gl-dropdown-divider />
        <gl-dropdown-item
          v-gl-modal="$options.deleteModalId"
          variant="danger"
          @click="track('click_dropdown')"
        >
          {{ deleteButtonText }}
        </gl-dropdown-item>
      </template>
      <gl-dropdown-item
        v-if="!isIssueAuthor"
        data-testid="report-abuse-item"
        @click="toggleReportAbuseDrawer(true)"
      >
        {{ $options.i18n.reportAbuse }}
      </gl-dropdown-item>
    </gl-dropdown>

    <gl-button
      v-if="canUpdateIssue"
      v-gl-tooltip.bottom
      :title="$options.i18n.editTitleAndDescription"
      :aria-label="$options.i18n.editTitleAndDescription"
      class="js-issuable-edit gl-display-none gl-sm-display-block"
      data-testid="edit-button"
      @click="edit"
    >
      {{ $options.i18n.edit }}
    </gl-button>

    <gl-button
      v-if="showToggleIssueStateButton"
      class="gl-display-none gl-sm-display-inline-flex! gl-sm-ml-3"
      :data-qa-selector="qaSelector"
      :loading="isToggleStateButtonLoading"
      data-testid="toggle-button"
      @click="toggleIssueState"
    >
      {{ buttonText }}
    </gl-button>

    <gl-dropdown
      v-if="hasDesktopDropdown"
      id="new-actions-header-dropdown"
      v-gl-tooltip.hover
      class="gl-display-none gl-sm-display-inline-flex! gl-sm-ml-3"
      icon="ellipsis_v"
      category="tertiary"
      data-qa-selector="issue_actions_ellipsis_dropdown"
      :text="dropdownText"
      :text-sr-only="true"
      :title="dropdownText"
      :aria-label="dropdownText"
      data-testid="desktop-dropdown"
      no-caret
      right
      @shown="dismissPopover"
    >
      <template v-if="isMrSidebarMoved">
        <sidebar-subscriptions-widget
          :iid="String(iid)"
          :full-path="fullPath"
          :issuable-type="$options.TYPE_ISSUE"
          data-testid="notification-toggle"
        />

        <gl-dropdown-divider />
      </template>

      <gl-dropdown-item v-if="canCreateIssue" :href="newIssuePath">
        {{ newIssueTypeText }}
      </gl-dropdown-item>
      <gl-dropdown-item
        v-if="canPromoteToEpic"
        :disabled="isToggleStateButtonLoading"
        data-testid="promote-button"
        @click="promoteToEpic"
      >
        {{ __('Promote to epic') }}
      </gl-dropdown-item>
      <template v-if="showLockIssueOption">
        <issuable-lock-form :is-editable="false" data-testid="lock-issue-toggle" />
      </template>
      <template v-if="isMrSidebarMoved">
        <gl-dropdown-item
          :data-clipboard-text="issuableReference"
          data-testid="copy-reference"
          @click="copyReference"
          >{{ $options.i18n.copyReferenceText }}</gl-dropdown-item
        >
        <gl-dropdown-item
          v-if="issuableEmailAddress"
          :data-clipboard-text="issuableEmailAddress"
          data-testid="copy-email"
          @click="copyEmailAddress"
          >{{ copyMailAddressText }}</gl-dropdown-item
        >
      </template>
      <gl-dropdown-item
        v-if="canReportSpam"
        :href="submitAsSpamPath"
        data-method="post"
        rel="nofollow"
      >
        {{ __('Submit as spam') }}
      </gl-dropdown-item>
      <template v-if="canDestroyIssue">
        <gl-dropdown-divider />
        <gl-dropdown-item
          v-gl-modal="$options.deleteModalId"
          variant="danger"
          data-qa-selector="delete_issue_button"
          @click="track('click_dropdown')"
        >
          {{ deleteButtonText }}
        </gl-dropdown-item>
      </template>
      <gl-dropdown-item
        v-if="!isIssueAuthor"
        data-testid="report-abuse-item"
        @click="toggleReportAbuseDrawer(true)"
      >
        {{ $options.i18n.reportAbuse }}
      </gl-dropdown-item>
    </gl-dropdown>

    <new-header-actions-popover v-if="isMrSidebarMoved" :issue-type="issueType" />
    <gl-modal
      ref="blockedByIssuesModal"
      modal-id="blocked-by-issues-modal"
      :action-cancel="$options.actionCancel"
      :action-primary="$options.actionPrimary"
      :title="__('Are you sure you want to close this blocked issue?')"
      @primary="invokeUpdateIssueMutation"
    >
      <p>{{ __('This issue is currently blocked by the following issues:') }}</p>
      <ul>
        <li v-for="issue in getBlockedByIssues" :key="issue.iid">
          <gl-link :href="issue.web_url">#{{ issue.iid }}</gl-link>
        </li>
      </ul>
    </gl-modal>

    <delete-issue-modal
      :issue-path="issuePath"
      :issue-type="issueType"
      :modal-id="$options.deleteModalId"
      :title="deleteButtonText"
    />

    <!-- IMPORTANT: show this component lazily because it causes layout thrashing -->
    <!-- https://gitlab.com/gitlab-org/gitlab/-/issues/331172#note_1269378396 -->
    <abuse-category-selector
      v-if="isReportAbuseDrawerOpen"
      :reported-user-id="reportedUserId"
      :reported-from-url="reportedFromUrl"
      :show-drawer="isReportAbuseDrawerOpen"
      @close-drawer="toggleReportAbuseDrawer(false)"
    />
  </div>
</template>
