<script>
import { GlButton, GlDropdown, GlDropdownItem, GlIcon, GlLink, GlModal } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import createFlash, { FLASH_TYPES } from '~/flash';
import { IssuableType } from '~/issuable_show/constants';
import { IssuableStatus, IssueStateEvent } from '~/issue_show/constants';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { visitUrl } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';
import eventHub from '~/notes/event_hub';
import promoteToEpicMutation from '../queries/promote_to_epic.mutation.graphql';
import updateIssueMutation from '../queries/update_issue.mutation.graphql';

export default {
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlIcon,
    GlLink,
    GlModal,
  },
  actionCancel: {
    text: __('Cancel'),
  },
  actionPrimary: {
    text: __('Yes, close issue'),
    attributes: [{ variant: 'warning' }],
  },
  i18n: {
    promoteErrorMessage: __(
      'Something went wrong while promoting the issue to an epic. Please try again.',
    ),
    promoteSuccessMessage: __(
      'The issue was successfully promoted to an epic. Redirecting to epic...',
    ),
  },
  inject: {
    canCreateIssue: {
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
    issueType: {
      default: IssuableType.Issue,
    },
    newIssuePath: {
      default: '',
    },
    projectPath: {
      default: '',
    },
    reportAbusePath: {
      default: '',
    },
    submitAsSpamPath: {
      default: '',
    },
  },
  computed: {
    ...mapState(['isToggleStateButtonLoading']),
    ...mapGetters(['openState', 'getBlockedByIssues']),
    isClosed() {
      return this.openState === IssuableStatus.Closed;
    },
    buttonText() {
      return this.isClosed
        ? sprintf(__('Reopen %{issueType}'), { issueType: this.issueType })
        : sprintf(__('Close %{issueType}'), { issueType: this.issueType });
    },
    qaSelector() {
      return this.isClosed ? 'reopen_issue_button' : 'close_issue_button';
    },
    buttonVariant() {
      return this.isClosed ? 'default' : 'warning';
    },
    dropdownText() {
      return sprintf(__('%{issueType} actions'), {
        issueType: capitalizeFirstCharacter(this.issueType),
      });
    },
    newIssueTypeText() {
      return sprintf(__('New %{issueType}'), { issueType: this.issueType });
    },
    showToggleIssueStateButton() {
      const canClose = !this.isClosed && this.canUpdateIssue;
      const canReopen = this.isClosed && this.canReopenIssue;
      return canClose || canReopen;
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
    toggleIssueState() {
      if (!this.isClosed && this.getBlockedByIssues?.length) {
        this.$refs.blockedByIssuesModal.show();
        return;
      }

      this.invokeUpdateIssueMutation();
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
              stateEvent: this.isClosed ? IssueStateEvent.Reopen : IssueStateEvent.Close,
            },
          },
        })
        .then(({ data }) => {
          if (data.updateIssue.errors.length) {
            createFlash({ message: data.updateIssue.errors.join('. ') });
            return;
          }

          const payload = {
            detail: {
              data: { id: this.iid },
              isClosed: !this.isClosed,
            },
          };

          // Dispatch event which updates open/close state, shared among the issue show page
          document.dispatchEvent(new CustomEvent('issuable_vue_app:change', payload));
        })
        .catch(() => createFlash({ message: __('Update failed. Please try again.') }))
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
            createFlash({ message: data.promoteToEpic.errors.join('; ') });
            return;
          }

          createFlash({
            message: this.$options.i18n.promoteSuccessMessage,
            type: FLASH_TYPES.SUCCESS,
          });

          visitUrl(data.promoteToEpic.epic.webPath);
        })
        .catch(() => createFlash({ message: this.$options.i18n.promoteErrorMessage }))
        .finally(() => {
          this.toggleStateButtonLoading(false);
        });
    },
  },
};
</script>

<template>
  <div class="detail-page-header-actions">
    <gl-dropdown class="gl-display-block gl-display-sm-none!" block :text="dropdownText">
      <gl-dropdown-item
        v-if="showToggleIssueStateButton"
        :disabled="isToggleStateButtonLoading"
        @click="toggleIssueState"
      >
        {{ buttonText }}
      </gl-dropdown-item>
      <gl-dropdown-item v-if="canCreateIssue" :href="newIssuePath">
        {{ newIssueTypeText }}
      </gl-dropdown-item>
      <gl-dropdown-item
        v-if="canPromoteToEpic"
        :disabled="isToggleStateButtonLoading"
        @click="promoteToEpic"
      >
        {{ __('Promote to epic') }}
      </gl-dropdown-item>
      <gl-dropdown-item v-if="!isIssueAuthor" :href="reportAbusePath">
        {{ __('Report abuse') }}
      </gl-dropdown-item>
      <gl-dropdown-item
        v-if="canReportSpam"
        :href="submitAsSpamPath"
        data-method="post"
        rel="nofollow"
      >
        {{ __('Submit as spam') }}
      </gl-dropdown-item>
    </gl-dropdown>

    <gl-button
      v-if="showToggleIssueStateButton"
      class="gl-display-none gl-display-sm-inline-flex!"
      category="secondary"
      :data-qa-selector="qaSelector"
      :loading="isToggleStateButtonLoading"
      :variant="buttonVariant"
      @click="toggleIssueState"
    >
      {{ buttonText }}
    </gl-button>

    <gl-dropdown
      class="gl-display-none gl-display-sm-inline-flex!"
      toggle-class="gl-border-0! gl-shadow-none!"
      no-caret
      right
    >
      <template #button-content>
        <gl-icon name="ellipsis_v" />
        <span class="gl-sr-only">{{ dropdownText }}</span>
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
      <gl-dropdown-item v-if="!isIssueAuthor" :href="reportAbusePath">
        {{ __('Report abuse') }}
      </gl-dropdown-item>
      <gl-dropdown-item
        v-if="canReportSpam"
        :href="submitAsSpamPath"
        data-method="post"
        rel="nofollow"
      >
        {{ __('Submit as spam') }}
      </gl-dropdown-item>
    </gl-dropdown>

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
  </div>
</template>
