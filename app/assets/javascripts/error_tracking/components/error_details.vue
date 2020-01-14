<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import dateFormat from 'dateformat';
import createFlash from '~/flash';
import { GlFormInput, GlLink, GlLoadingIcon, GlBadge } from '@gitlab/ui';
import { __, sprintf, n__ } from '~/locale';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import Icon from '~/vue_shared/components/icon.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import Stacktrace from './stacktrace.vue';
import TrackEventDirective from '~/vue_shared/directives/track_event';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { trackClickErrorLinkToSentryOptions } from '../utils';

import query from '../queries/details.query.graphql';

export default {
  components: {
    LoadingButton,
    GlFormInput,
    GlLink,
    GlLoadingIcon,
    TooltipOnTruncate,
    Icon,
    Stacktrace,
    GlBadge,
  },
  directives: {
    TrackEvent: TrackEventDirective,
  },
  mixins: [timeagoMixin],
  props: {
    issueId: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    issueDetailsPath: {
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
    GQLerror: {
      query,
      variables() {
        return {
          fullPath: this.projectPath,
          errorId: `gid://gitlab/Gitlab::ErrorTracking::DetailedError/${this.issueId}`,
        };
      },
      pollInterval: 2000,
      update: data => data.project.sentryDetailedError,
      error: () => createFlash(__('Failed to load error details from Sentry.')),
      result(res) {
        if (res.data.project?.sentryDetailedError) {
          this.$apollo.queries.GQLerror.stopPolling();
        }
      },
    },
  },
  data() {
    return {
      GQLerror: null,
      issueCreationInProgress: false,
    };
  },
  computed: {
    ...mapState('details', ['error', 'loading', 'loadingStacktrace', 'stacktraceData']),
    ...mapGetters('details', ['stacktrace']),
    reported() {
      return sprintf(
        __('Reported %{timeAgo} by %{reportedBy}'),
        {
          reportedBy: `<strong>${this.GQLerror.culprit}</strong>`,
          timeAgo: this.timeFormatted(this.stacktraceData.date_received),
        },
        false,
      );
    },
    firstReleaseLink() {
      return `${this.error.external_base_url}/releases/${this.GQLerror.firstReleaseShortVersion}`;
    },
    lastReleaseLink() {
      return `${this.error.external_base_url}releases/${this.GQLerror.lastReleaseShortVersion}`;
    },
    showDetails() {
      return Boolean(
        !this.loading && !this.$apollo.queries.GQLerror.loading && this.error && this.GQLerror,
      );
    },
    showStacktrace() {
      return Boolean(!this.loadingStacktrace && this.stacktrace && this.stacktrace.length);
    },
    issueTitle() {
      return this.GQLerror.title;
    },
    issueDescription() {
      return sprintf(
        __(
          '%{description}- Sentry event: %{errorUrl}- First seen: %{firstSeen}- Last seen: %{lastSeen} %{countLabel}: %{count}%{userCountLabel}: %{userCount}',
        ),
        {
          description: '# Error Details:\n',
          errorUrl: `${this.GQLerror.externalUrl}\n`,
          firstSeen: `\n${this.GQLerror.firstSeen}\n`,
          lastSeen: `${this.GQLerror.lastSeen}\n`,
          countLabel: n__('- Event', '- Events', this.GQLerror.count),
          count: `${this.GQLerror.count}\n`,
          userCountLabel: n__('- User', '- Users', this.GQLerror.userCount),
          userCount: `${this.GQLerror.userCount}\n`,
        },
        false,
      );
    },
    errorLevel() {
      return sprintf(__('level: %{level}'), { level: this.error.tags.level });
    },
  },
  mounted() {
    this.startPollingDetails(this.issueDetailsPath);
    this.startPollingStacktrace(this.issueStackTracePath);
  },
  methods: {
    ...mapActions('details', ['startPollingDetails', 'startPollingStacktrace']),
    trackClickErrorLinkToSentryOptions,
    createIssue() {
      this.issueCreationInProgress = true;
      this.$refs.sentryIssueForm.submit();
    },
    formatDate(date) {
      return `${this.timeFormatted(date)} (${dateFormat(date, 'UTC:yyyy-mm-dd h:MM:ssTT Z')})`;
    },
  },
};
</script>

<template>
  <div>
    <div v-if="$apollo.queries.GQLerror.loading || loading" class="py-3">
      <gl-loading-icon :size="3" />
    </div>
    <div v-else-if="showDetails" class="error-details">
      <div class="top-area align-items-center justify-content-between py-3">
        <span v-if="!loadingStacktrace && stacktrace" v-html="reported"></span>
        <form ref="sentryIssueForm" :action="projectIssuesPath" method="POST">
          <gl-form-input class="hidden" name="issue[title]" :value="issueTitle" />
          <input name="issue[description]" :value="issueDescription" type="hidden" />
          <gl-form-input
            :value="GQLerror.id"
            class="hidden"
            name="issue[sentry_issue_attributes][sentry_issue_identifier]"
          />
          <gl-form-input :value="csrfToken" class="hidden" name="authenticity_token" />
          <loading-button
            v-if="!error.gitlab_issue"
            class="btn-success"
            :label="__('Create issue')"
            :loading="issueCreationInProgress"
            data-qa-selector="create_issue_button"
            @click="createIssue"
          />
        </form>
      </div>
      <div>
        <tooltip-on-truncate :title="GQLerror.title" truncate-target="child" placement="top">
          <h2 class="text-truncate">{{ GQLerror.title }}</h2>
        </tooltip-on-truncate>
        <template v-if="error.tags">
          <gl-badge v-if="error.tags.level" variant="danger" class="rounded-pill mr-2"
            >{{ errorLevel }}
          </gl-badge>
          <gl-badge v-if="error.tags.logger" variant="light" class="rounded-pill"
            >{{ error.tags.logger }}
          </gl-badge>
        </template>

        <h3>{{ __('Error details') }}</h3>
        <ul>
          <li v-if="error.gitlab_issue">
            <span class="bold">{{ __('GitLab Issue') }}:</span>
            <gl-link :href="error.gitlab_issue">
              <span>{{ error.gitlab_issue }}</span>
            </gl-link>
          </li>
          <li>
            <span class="bold">{{ __('Sentry event') }}:</span>
            <gl-link
              v-track-event="trackClickErrorLinkToSentryOptions(GQLerror.externalUrl)"
              :href="GQLerror.externalUrl"
              target="_blank"
            >
              <span class="text-truncate">{{ GQLerror.externalUrl }}</span>
              <icon name="external-link" class="ml-1 flex-shrink-0" />
            </gl-link>
          </li>
          <li v-if="GQLerror.firstReleaseShortVersion">
            <span class="bold">{{ __('First seen') }}:</span>
            {{ formatDate(GQLerror.firstSeen) }}
            <gl-link :href="firstReleaseLink" target="_blank">
              <span>{{ __('Release') }}: {{ GQLerror.firstReleaseShortVersion }}</span>
            </gl-link>
          </li>
          <li v-if="GQLerror.lastReleaseShortVersion">
            <span class="bold">{{ __('Last seen') }}:</span>
            {{ formatDate(GQLerror.lastSeen) }}
            <gl-link :href="lastReleaseLink" target="_blank">
              <span>{{ __('Release') }}: {{ GQLerror.lastReleaseShortVersion }}</span>
            </gl-link>
          </li>
          <li>
            <span class="bold">{{ __('Events') }}:</span>
            <span>{{ GQLerror.count }}</span>
          </li>
          <li>
            <span class="bold">{{ __('Users') }}:</span>
            <span>{{ GQLerror.userCount }}</span>
          </li>
        </ul>

        <div v-if="loadingStacktrace" class="py-3">
          <gl-loading-icon :size="3" />
        </div>

        <template v-if="showStacktrace">
          <h3 class="my-4">{{ __('Stack trace') }}</h3>
          <stacktrace :entries="stacktrace" />
        </template>
      </div>
    </div>
  </div>
</template>
