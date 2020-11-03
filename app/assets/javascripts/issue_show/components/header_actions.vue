<script>
import { GlButton, GlDropdown, GlDropdownItem, GlIcon, GlLink, GlModal } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import createFlash from '~/flash';
import { IssuableStatus, IssueStateEvent } from '~/issue_show/constants';
import { __ } from '~/locale';
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
  inject: [
    'canCreateIssue',
    'canReopenIssue',
    'canReportSpam',
    'canUpdateIssue',
    'iid',
    'isIssueAuthor',
    'newIssuePath',
    'projectPath',
    'reportAbusePath',
    'submitAsSpamPath',
  ],
  data() {
    return {
      isUpdatingState: false,
    };
  },
  computed: {
    ...mapGetters(['getNoteableData']),
    isClosed() {
      return this.getNoteableData.state === IssuableStatus.Closed;
    },
    buttonText() {
      return this.isClosed ? __('Reopen issue') : __('Close issue');
    },
    buttonVariant() {
      return this.isClosed ? 'default' : 'warning';
    },
    showToggleIssueButton() {
      const canClose = !this.isClosed && this.canUpdateIssue;
      const canReopen = this.isClosed && this.canReopenIssue;
      return canClose || canReopen;
    },
  },
  methods: {
    toggleIssueState() {
      if (!this.isClosed && this.getNoteableData?.blocked_by_issues?.length) {
        this.$refs.blockedByIssuesModal.show();
        return;
      }

      this.invokeUpdateIssueMutation();
    },
    invokeUpdateIssueMutation() {
      this.isUpdatingState = true;

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
            createFlash(data.updateIssue.errors.join('. '));
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
        .catch(() => createFlash(__('Update failed. Please try again.')))
        .finally(() => {
          this.isUpdatingState = false;
        });
    },
  },
};
</script>

<template>
  <div class="detail-page-header-actions">
    <gl-dropdown class="gl-display-block gl-display-sm-none!" block :text="__('Issue actions')">
      <gl-dropdown-item
        v-if="showToggleIssueButton"
        :disabled="isUpdatingState"
        @click="toggleIssueState"
      >
        {{ buttonText }}
      </gl-dropdown-item>
      <gl-dropdown-item v-if="canCreateIssue" :href="newIssuePath">
        {{ __('New issue') }}
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
      v-if="showToggleIssueButton"
      class="gl-display-none gl-display-sm-inline-flex!"
      category="secondary"
      :loading="isUpdatingState"
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
        <gl-icon name="ellipsis_v" aria-hidden="true" />
        <span class="gl-sr-only">{{ __('Actions') }}</span>
      </template>

      <gl-dropdown-item v-if="canCreateIssue" :href="newIssuePath">
        {{ __('New issue') }}
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
        <li v-for="issue in getNoteableData.blocked_by_issues" :key="issue.iid">
          <gl-link :href="issue.web_url">#{{ issue.iid }}</gl-link>
        </li>
      </ul>
    </gl-modal>
  </div>
</template>
