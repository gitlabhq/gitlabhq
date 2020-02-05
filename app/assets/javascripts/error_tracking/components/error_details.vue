<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import dateFormat from 'dateformat';
import createFlash from '~/flash';
import {
  GlButton,
  GlFormInput,
  GlLink,
  GlLoadingIcon,
  GlBadge,
  GlAlert,
  GlSprintf,
} from '@gitlab/ui';
import { __, sprintf, n__ } from '~/locale';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import Icon from '~/vue_shared/components/icon.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import Stacktrace from './stacktrace.vue';
import TrackEventDirective from '~/vue_shared/directives/track_event';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { trackClickErrorLinkToSentryOptions } from '../utils';
import { severityLevel, severityLevelVariant, errorStatus } from './constants';

import query from '../queries/details.query.graphql';

export default {
  components: {
    LoadingButton,
    GlButton,
    GlFormInput,
    GlLink,
    GlLoadingIcon,
    TooltipOnTruncate,
    Icon,
    Stacktrace,
    GlBadge,
    GlAlert,
    GlSprintf,
  },
  directives: {
    TrackEvent: TrackEventDirective,
  },
  mixins: [timeagoMixin],
  props: {
    issueUpdatePath: {
      type: String,
      required: true,
    },
    issueId: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    issueStackTracePath: {
      type: String,
      required: true,
    },
    projectIssuesPath: {
      type: String,
      required: true,
    },
    csrfToken: {
      type: String,
      required: true,
    },
  },
  apollo: {
    error: {
      query,
      variables() {
        return {
          fullPath: this.projectPath,
          errorId: `gid://gitlab/Gitlab::ErrorTracking::DetailedError/${this.issueId}`,
        };
      },
      pollInterval: 2000,
      update: data => data.project.sentryErrors.detailedError,
      error: () => createFlash(__('Failed to load error details from Sentry.')),
      result(res) {
        if (res.data.project?.sentryErrors?.detailedError) {
          this.$apollo.queries.error.stopPolling();
          this.setStatus(this.error.status);
        }
      },
    },
  },
  data() {
    return {
      error: null,
      issueCreationInProgress: false,
      isAlertVisible: false,
      closedIssueId: null,
    };
  },
  computed: {
    ...mapState('details', [
      'loadingStacktrace',
      'stacktraceData',
      'updatingResolveStatus',
      'updatingIgnoreStatus',
      'errorStatus',
    ]),
    ...mapGetters('details', ['stacktrace']),
    reported() {
      return sprintf(
        __('Reported %{timeAgo} by %{reportedBy}'),
        {
          reportedBy: `<strong>${this.error.culprit}</strong>`,
          timeAgo: this.timeFormatted(this.stacktraceData.date_received),
        },
        false,
      );
    },
    firstReleaseLink() {
      return `${this.error.externalBaseUrl}/releases/${this.error.firstReleaseShortVersion}`;
    },
    lastReleaseLink() {
      return `${this.error.externalBaseUrl}/releases/${this.error.lastReleaseShortVersion}`;
    },
    showStacktrace() {
      return Boolean(this.stacktrace?.length);
    },
    issueTitle() {
      return this.error.title;
    },
    issueDescription() {
      return sprintf(
        __(
          '%{description}- Sentry event: %{errorUrl}- First seen: %{firstSeen}- Last seen: %{lastSeen} %{countLabel}: %{count}%{userCountLabel}: %{userCount}',
        ),
        {
          description: '# Error Details:\n',
          errorUrl: `${this.error.externalUrl}\n`,
          firstSeen: `\n${this.error.firstSeen}\n`,
          lastSeen: `${this.error.lastSeen}\n`,
          countLabel: n__('- Event', '- Events', this.error.count),
          count: `${this.error.count}\n`,
          userCountLabel: n__('- User', '- Users', this.error.userCount),
          userCount: `${this.error.userCount}\n`,
        },
        false,
      );
    },
    errorLevel() {
      return sprintf(__('level: %{level}'), { level: this.error.tags.level });
    },
    errorSeverityVariant() {
      return (
        severityLevelVariant[this.error.tags.level] || severityLevelVariant[severityLevel.ERROR]
      );
    },
    ignoreBtnLabel() {
      return this.errorStatus !== errorStatus.IGNORED ? __('Ignore') : __('Undo ignore');
    },
    resolveBtnLabel() {
      return this.errorStatus !== errorStatus.RESOLVED ? __('Resolve') : __('Unresolve');
    },
  },
  mounted() {
    this.startPollingStacktrace(this.issueStackTracePath);
  },
  methods: {
    ...mapActions('details', [
      'startPollingStacktrace',
      'updateStatus',
      'setStatus',
      'updateResolveStatus',
      'updateIgnoreStatus',
    ]),
    trackClickErrorLinkToSentryOptions,
    createIssue() {
      this.issueCreationInProgress = true;
      this.$refs.sentryIssueForm.submit();
    },
    onIgnoreStatusUpdate() {
      const status =
        this.errorStatus === errorStatus.IGNORED ? errorStatus.UNRESOLVED : errorStatus.IGNORED;
      this.updateIgnoreStatus({ endpoint: this.issueUpdatePath, status });
    },
    onResolveStatusUpdate() {
      const status =
        this.errorStatus === errorStatus.RESOLVED ? errorStatus.UNRESOLVED : errorStatus.RESOLVED;

      // eslint-disable-next-line promise/catch-or-return
      this.updateResolveStatus({ endpoint: this.issueUpdatePath, status }).then(res => {
        this.closedIssueId = res.closed_issue_iid;
        if (this.closedIssueId) {
          this.isAlertVisible = true;
        }
      });
    },
    formatDate(date) {
      return `${this.timeFormatted(date)} (${dateFormat(date, 'UTC:yyyy-mm-dd h:MM:ssTT Z')})`;
    },
  },
};
</script>

<template>
  <div>
    <div v-if="$apollo.queries.error.loading" class="py-3">
      <gl-loading-icon :size="3" />
    </div>
    <div v-else-if="error" class="error-details">
      <gl-alert v-if="isAlertVisible" @dismiss="isAlertVisible = false">
        <gl-sprintf
          :message="
            __('The associated issue #%{issueId} has been closed as the error is now resolved.')
          "
        >
          <template #issueId>
            <span>{{ closedIssueId }}</span>
          </template>
        </gl-sprintf>
      </gl-alert>

      <div class="top-area align-items-center justify-content-between py-3">
        <span v-if="!loadingStacktrace && stacktrace" v-html="reported"></span>
        <div class="d-inline-flex ml-lg-auto">
          <loading-button
            :label="ignoreBtnLabel"
            :loading="updatingIgnoreStatus"
            data-qa-selector="update_ignore_status_button"
            @click="onIgnoreStatusUpdate"
          />
          <loading-button
            class="btn-outline-info ml-2"
            :label="resolveBtnLabel"
            :loading="updatingResolveStatus"
            data-qa-selector="update_resolve_status_button"
            @click="onResolveStatusUpdate"
          />
          <gl-button
            v-if="error.gitlabIssuePath"
            class="ml-2"
            data-qa-selector="view_issue_button"
            :href="error.gitlabIssuePath"
            variant="success"
          >
            {{ __('View issue') }}
          </gl-button>
          <form
            ref="sentryIssueForm"
            :action="projectIssuesPath"
            method="POST"
            class="d-inline-block ml-2"
          >
            <gl-form-input class="hidden" name="issue[title]" :value="issueTitle" />
            <input name="issue[description]" :value="issueDescription" type="hidden" />
            <gl-form-input
              :value="error.sentryId"
              class="hidden"
              name="issue[sentry_issue_attributes][sentry_issue_identifier]"
            />
            <gl-form-input :value="csrfToken" class="hidden" name="authenticity_token" />
            <loading-button
              v-if="!error.gitlabIssuePath"
              class="btn-success"
              :label="__('Create issue')"
              :loading="issueCreationInProgress"
              data-qa-selector="create_issue_button"
              @click="createIssue"
            />
          </form>
        </div>
      </div>
      <div>
        <tooltip-on-truncate :title="error.title" truncate-target="child" placement="top">
          <h2 class="text-truncate">{{ error.title }}</h2>
        </tooltip-on-truncate>
        <template v-if="error.tags">
          <gl-badge
            v-if="error.tags.level"
            :variant="errorSeverityVariant"
            class="rounded-pill mr-2"
          >
            {{ errorLevel }}
          </gl-badge>
          <gl-badge v-if="error.tags.logger" variant="light" class="rounded-pill"
            >{{ error.tags.logger }}
          </gl-badge>
        </template>
        <ul>
          <li v-if="error.gitlabCommit">
            <strong class="bold">{{ __('GitLab commit') }}:</strong>
            <gl-link :href="error.gitlabCommitPath">
              <span>{{ error.gitlabCommit.substr(0, 10) }}</span>
            </gl-link>
          </li>
          <li v-if="error.gitlabIssuePath">
            <strong class="bold">{{ __('GitLab Issue') }}:</strong>
            <gl-link :href="error.gitlabIssuePath">
              <span>{{ error.gitlabIssuePath }}</span>
            </gl-link>
          </li>
          <li>
            <strong class="bold">{{ __('Sentry event') }}:</strong>
            <gl-link
              v-track-event="trackClickErrorLinkToSentryOptions(error.externalUrl)"
              class="d-inline-flex align-items-center"
              :href="error.externalUrl"
              target="_blank"
            >
              <span class="text-truncate">{{ error.externalUrl }}</span>
              <icon name="external-link" class="ml-1 flex-shrink-0" />
            </gl-link>
          </li>
          <li v-if="error.firstReleaseShortVersion">
            <strong class="bold">{{ __('First seen') }}:</strong>
            {{ formatDate(error.firstSeen) }}
            <gl-link :href="firstReleaseLink" target="_blank">
              <span>{{ __('Release') }}: {{ error.firstReleaseShortVersion.substr(0, 10) }}</span>
            </gl-link>
          </li>
          <li v-if="error.lastReleaseShortVersion">
            <strong class="bold">{{ __('Last seen') }}:</strong>
            {{ formatDate(error.lastSeen) }}
            <gl-link :href="lastReleaseLink" target="_blank">
              <span>{{ __('Release') }}: {{ error.lastReleaseShortVersion.substr(0, 10) }}</span>
            </gl-link>
          </li>
          <li>
            <strong class="bold">{{ __('Events') }}:</strong>
            <span>{{ error.count }}</span>
          </li>
          <li>
            <strong class="bold">{{ __('Users') }}:</strong>
            <span>{{ error.userCount }}</span>
          </li>
        </ul>

        <div v-if="loadingStacktrace" class="py-3">
          <gl-loading-icon :size="3" />
        </div>

        <template v-else-if="showStacktrace">
          <h3 class="my-4">{{ __('Stack trace') }}</h3>
          <stacktrace :entries="stacktrace" />
        </template>
      </div>
    </div>
  </div>
</template>
