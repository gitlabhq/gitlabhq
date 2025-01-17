<script>
import {
  GlButton,
  GlDisclosureDropdown,
  GlDropdownDivider,
  GlDisclosureDropdownItem,
  GlLink,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { EVENT_ISSUABLE_VUE_APP_CHANGE } from '~/issuable/constants';
import { keysFor, ISSUABLE_EDIT_DESCRIPTION } from '~/behaviors/shortcuts/keybindings';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { sanitize } from '~/lib/dompurify';
import { STATUS_CLOSED, TYPE_ISSUE, TYPE_INCIDENT, issuableTypeText } from '~/issues/constants';
import { ISSUE_STATE_EVENT_CLOSE, ISSUE_STATE_EVENT_REOPEN } from '~/issues/show/constants';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';
import eventHub from '~/notes/event_hub';
import Tracking from '~/tracking';
import toast from '~/vue_shared/plugins/global_toast';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import SidebarSubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import IssuableLockForm from '~/sidebar/components/lock/issuable_lock_form.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import issueReferenceQuery from '~/sidebar/queries/issue_reference.query.graphql';
import issuesEventHub from '../event_hub';
import promoteToEpicMutation from '../queries/promote_to_epic.mutation.graphql';
import updateIssueMutation from '../queries/update_issue.mutation.graphql';
import DeleteIssueModal from './delete_issue_modal.vue';
import HeaderActionsConfidentialityToggle from './header_actions_confidentiality_toggle.vue';

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
    reportAbuse: __('Report abuse'),
    referenceFetchError: __('An error occurred while fetching reference'),
    copyReferenceText: __('Copy reference'),
  },
  components: {
    DeleteIssueModal,
    GlButton,
    GlDisclosureDropdown,
    GlDropdownDivider,
    GlDisclosureDropdownItem,
    GlLink,
    GlModal,
    AbuseCategorySelector,
    SidebarSubscriptionsWidget,
    IssuableLockForm,
    HeaderActionsConfidentialityToggle,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  mixins: [trackingMixin, glFeatureFlagMixin()],
  inject: [
    'canCreateIssue',
    'canDestroyIssue',
    'canPromoteToEpic',
    'canReopenIssue',
    'canReportSpam',
    'canUpdateIssue',
    'iid',
    'isIssueAuthor',
    'issuePath',
    'issueType',
    'newIssuePath',
    'projectPath',
    'submitAsSpamPath',
    'reportedUserId',
    'reportedFromUrl',
    'issuableEmailAddress',
    'fullPath',
  ],
  data() {
    return {
      isReportAbuseDrawerOpen: false,
      isUserSignedIn: isLoggedIn(),
      isDesktopDropdownVisible: false,
    };
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    issuableReference: {
      query: issueReferenceQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: String(this.iid),
        };
      },
      update(data) {
        return data.workspace?.issuable?.reference || '';
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
      const { issueType } = this;

      return issuableTypeText[issueType] ?? issueType;
    },
    buttonText() {
      return this.isClosed
        ? sprintf(__('Reopen %{issueType}'), { issueType: this.issueTypeText })
        : sprintf(__('Close %{issueType}'), { issueType: this.issueTypeText });
    },
    deleteButtonText() {
      return sprintf(__('Delete %{issuableType}'), { issuableType: this.issueTypeText });
    },
    testId() {
      return this.isClosed ? 'reopen-issue-button' : 'close-issue-button';
    },
    dropdownText() {
      return sprintf(__('%{issueType} actions'), {
        issueType: capitalizeFirstCharacter(this.issueTypeText),
      });
    },
    newIssueTypeText() {
      return sprintf(__('New related %{issueType}'), { issueType: this.issueTypeText });
    },
    showToggleIssueStateButton() {
      const canClose = !this.isClosed && this.canUpdateIssue;
      const canReopen = this.isClosed && this.canReopenIssue;
      return canClose || canReopen;
    },
    hasDesktopDropdown() {
      return (
        this.canCreateIssue ||
        this.canPromoteToEpic ||
        !this.isIssueAuthor ||
        this.canReportSpam ||
        this.issuableReference
      );
    },
    hasMobileDropdown() {
      return this.hasDesktopDropdown || this.showToggleIssueStateButton;
    },
    copyMailAddressText() {
      return sprintf(__('Copy %{issueType} email address'), {
        issueType: this.issueTypeText,
      });
    },
    showLockIssueOption() {
      return this.issueType === TYPE_ISSUE && this.isUserSignedIn && this.canUpdateIssue;
    },
    showMovedSidebarOptions() {
      return this.isUserSignedIn;
    },
    newIssueItem() {
      return {
        text: this.newIssueTypeText,
        href: this.newIssuePath,
      };
    },
    submitSpamItem() {
      return {
        text: __('Submit as spam'),
        href: this.submitAsSpamPath,
      };
    },
    editShortcutKey() {
      return shouldDisableShortcuts() ? null : keysFor(ISSUABLE_EDIT_DESCRIPTION)[0];
    },
    editTooltip() {
      const description = this.$options.i18n.editTitleAndDescription;
      const key = this.editShortcutKey;
      return shouldDisableShortcuts()
        ? description
        : sanitize(`${description} <kbd class="flat gl-ml-1" aria-hidden=true>${key}</kbd>`);
    },
    showDropdownTooltip() {
      return !this.isDesktopDropdownVisible ? this.dropdownText : '';
    },
    promoteToEpicItem() {
      return {
        text: __('Promote to epic'),
        extraAttrs: {
          disabled: this.isToggleStateButtonLoading,
        },
      };
    },
    showConfidentialityToggle() {
      return [TYPE_ISSUE, TYPE_INCIDENT].includes(this.issueType) && this.canUpdateIssue;
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
        this.closeActionsDropdown();
        return;
      }

      this.invokeUpdateIssueMutation();
    },
    toggleReportAbuseDrawer(isOpen) {
      this.isReportAbuseDrawerOpen = isOpen;
      this.closeActionsDropdown();
    },
    invokeUpdateIssueMutation() {
      this.toggleStateButtonLoading(true);

      this.$apollo
        .mutate({
          mutation: updateIssueMutation,
          variables: {
            input: {
              iid: String(this.iid),
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
          this.closeActionsDropdown();
        });
    },
    promoteToEpic() {
      this.toggleStateButtonLoading(true);

      this.$apollo
        .mutate({
          mutation: promoteToEpicMutation,
          variables: {
            input: {
              iid: String(this.iid),
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
          this.closeActionsDropdown();
        });
    },
    edit() {
      issuesEventHub.$emit('open.form');
      this.closeActionsDropdown();
    },
    copyReference() {
      toast(__('Reference copied'));
      this.closeActionsDropdown();
    },
    copyEmailAddress() {
      toast(__('Email address copied'));
      this.closeActionsDropdown();
    },
    closeActionsDropdown() {
      this.$refs.issuableActionsDropdownMobile?.close();
      this.$refs.issuableActionsDropdownDesktop?.close();
    },
    showDesktopDropdown() {
      this.isDesktopDropdownVisible = true;
    },
    hideDesktopDropdown() {
      this.isDesktopDropdownVisible = false;
    },
  },
  TYPE_ISSUE,
};
</script>

<template>
  <div
    class="detail-page-header-actions gl-mt-1 gl-flex gl-w-full gl-self-start sm:gl-gap-3 md:gl-w-auto"
  >
    <div class="gl-w-full md:!gl-hidden">
      <gl-disclosure-dropdown
        v-if="hasMobileDropdown"
        ref="issuableActionsDropdownMobile"
        toggle-class="gl-w-full"
        block
        :toggle-text="dropdownText"
        :auto-close="false"
        data-testid="mobile-dropdown"
        :loading="isToggleStateButtonLoading"
        placement="bottom-end"
      >
        <template v-if="showMovedSidebarOptions && !glFeatures.notificationsTodosButtons">
          <sidebar-subscriptions-widget
            :iid="String(iid)"
            :full-path="fullPath"
            :issuable-type="$options.TYPE_ISSUE"
            data-testid="notification-toggle"
          />

          <gl-dropdown-divider />
        </template>

        <gl-disclosure-dropdown-item v-if="canUpdateIssue" @action="edit">
          <template #list-item>{{ $options.i18n.edit }}</template>
        </gl-disclosure-dropdown-item>
        <gl-disclosure-dropdown-item
          v-if="showToggleIssueStateButton"
          :data-testid="`mobile-${testId}`"
          @action="toggleIssueState"
        >
          <template #list-item>{{ buttonText }}</template>
        </gl-disclosure-dropdown-item>
        <gl-disclosure-dropdown-item v-if="canCreateIssue" :item="newIssueItem" />
        <gl-disclosure-dropdown-item
          v-if="canPromoteToEpic"
          :item="promoteToEpicItem"
          @action="promoteToEpic"
        />
        <template v-if="showLockIssueOption">
          <issuable-lock-form :is-editable="false" data-testid="lock-issue-toggle" />
        </template>
        <header-actions-confidentiality-toggle
          v-if="showConfidentialityToggle"
          @closeActionsDropdown="closeActionsDropdown"
        />
        <gl-disclosure-dropdown-item
          :data-clipboard-text="issuableReference"
          class="js-copy-reference"
          data-testid="copy-reference"
          @action="copyReference"
          ><template #list-item>{{
            $options.i18n.copyReferenceText
          }}</template></gl-disclosure-dropdown-item
        >
        <gl-disclosure-dropdown-item
          v-if="issuableEmailAddress && showMovedSidebarOptions"
          :data-clipboard-text="issuableEmailAddress"
          data-testid="copy-email"
          @action="copyEmailAddress"
          ><template #list-item>{{ copyMailAddressText }}</template></gl-disclosure-dropdown-item
        >
        <gl-disclosure-dropdown-item
          v-if="canReportSpam"
          :item="submitSpamItem"
          data-method="post"
          rel="nofollow"
        />
        <template v-if="canDestroyIssue">
          <gl-dropdown-divider />
          <gl-disclosure-dropdown-item
            v-gl-modal="$options.deleteModalId"
            @action="track('click_dropdown')"
          >
            <template #list-item>
              <span class="gl-text-red-500">{{ deleteButtonText }}</span>
            </template>
          </gl-disclosure-dropdown-item>
        </template>
        <gl-disclosure-dropdown-item
          v-if="!isIssueAuthor && isUserSignedIn"
          data-testid="report-abuse-item"
          @action="toggleReportAbuseDrawer(true)"
        >
          <template #list-item>{{ $options.i18n.reportAbuse }}</template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown>
    </div>

    <gl-button
      v-if="canUpdateIssue"
      v-gl-tooltip.viewport.html
      :title="editTooltip"
      :aria-label="$options.i18n.editTitleAndDescription"
      :aria-keyshortcuts="editShortcutKey"
      class="js-issuable-edit !gl-hidden md:!gl-block"
      data-testid="edit-button"
      @click="edit"
    >
      {{ $options.i18n.edit }}
    </gl-button>

    <gl-disclosure-dropdown
      v-if="hasDesktopDropdown"
      id="new-actions-header-dropdown"
      ref="issuableActionsDropdownDesktop"
      v-gl-tooltip="showDropdownTooltip"
      class="gl-hidden md:!gl-inline-flex"
      icon="ellipsis_v"
      category="tertiary"
      :toggle-text="dropdownText"
      text-sr-only
      :title="dropdownText"
      :aria-label="dropdownText"
      :auto-close="false"
      data-testid="desktop-dropdown"
      no-caret
      @shown="showDesktopDropdown"
      @hidden="hideDesktopDropdown"
    >
      <template v-if="showMovedSidebarOptions && !glFeatures.notificationsTodosButtons">
        <sidebar-subscriptions-widget
          :iid="String(iid)"
          :full-path="fullPath"
          :issuable-type="$options.TYPE_ISSUE"
          data-testid="notification-toggle"
        />
        <gl-dropdown-divider />
      </template>
      <gl-disclosure-dropdown-item
        v-if="showToggleIssueStateButton"
        data-testid="toggle-issue-state-button"
        @action="toggleIssueState"
      >
        <template #list-item>{{ buttonText }}</template>
      </gl-disclosure-dropdown-item>
      <gl-disclosure-dropdown-item v-if="canCreateIssue && isUserSignedIn" :item="newIssueItem" />
      <gl-disclosure-dropdown-item
        v-if="canPromoteToEpic"
        :item="promoteToEpicItem"
        data-testid="promote-button"
        @action="promoteToEpic"
      />
      <template v-if="showLockIssueOption">
        <issuable-lock-form :is-editable="false" data-testid="lock-issue-toggle" />
      </template>
      <header-actions-confidentiality-toggle
        v-if="showConfidentialityToggle"
        @closeActionsDropdown="closeActionsDropdown"
      />
      <gl-disclosure-dropdown-item
        :data-clipboard-text="issuableReference"
        class="js-copy-reference"
        data-testid="copy-reference"
        @action="copyReference"
        ><template #list-item>{{
          $options.i18n.copyReferenceText
        }}</template></gl-disclosure-dropdown-item
      >
      <gl-disclosure-dropdown-item
        v-if="issuableEmailAddress && showMovedSidebarOptions"
        :data-clipboard-text="issuableEmailAddress"
        data-testid="copy-email"
        @action="copyEmailAddress"
        ><template #list-item>{{ copyMailAddressText }}</template></gl-disclosure-dropdown-item
      >
      <gl-dropdown-divider v-if="canDestroyIssue || canReportSpam || !isIssueAuthor" />
      <gl-disclosure-dropdown-item
        v-if="canReportSpam"
        :item="submitSpamItem"
        data-method="post"
        rel="nofollow"
      />
      <gl-disclosure-dropdown-item
        v-if="!isIssueAuthor && isUserSignedIn"
        data-testid="report-abuse-item"
        @action="toggleReportAbuseDrawer(true)"
      >
        <template #list-item>{{ $options.i18n.reportAbuse }}</template>
      </gl-disclosure-dropdown-item>
      <template v-if="canDestroyIssue">
        <gl-disclosure-dropdown-item
          v-gl-modal="$options.deleteModalId"
          data-testid="delete-issue-button"
          @action="track('click_dropdown')"
        >
          <template #list-item>
            <span class="gl-text-danger">
              {{ deleteButtonText }}
            </span>
          </template>
        </gl-disclosure-dropdown-item>
      </template>
    </gl-disclosure-dropdown>

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
