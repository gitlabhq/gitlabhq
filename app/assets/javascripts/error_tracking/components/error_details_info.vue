<script>
import { GlLink, GlIcon, GlCard, GlTooltipDirective } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import TrackEventDirective from '~/vue_shared/directives/track_event';
import { trackClickErrorLinkToSentryOptions } from '../utils';

const CARD_CLASS = 'gl-mr-7 gl-w-15p gl-min-w-fit-content';
const HEADER_CLASS =
  'gl-p-2 gl-font-weight-bold gl-display-flex gl-justify-content-center gl-align-items-center';
const BODY_CLASS =
  'gl-display-flex gl-justify-content-center gl-align-items-center gl-flex-direction-column gl-my-0 gl-p-4 gl-font-weight-bold gl-text-center gl-flex-grow-1 gl-font-lg';

export default {
  components: {
    GlCard,
    GlLink,
    TimeAgoTooltip,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    TrackEvent: TrackEventDirective,
  },
  props: {
    error: {
      type: Object,
      required: true,
    },
  },
  computed: {
    firstReleaseLink() {
      return `${this.error.externalBaseUrl}/releases/${this.error.firstReleaseVersion}`;
    },
    lastReleaseLink() {
      return `${this.error.externalBaseUrl}/releases/${this.error.lastReleaseVersion}`;
    },
    firstCommitLink() {
      return `${this.error.externalBaseUrl}/-/commit/${this.error.firstReleaseVersion}`;
    },
    lastCommitLink() {
      return `${this.error.externalBaseUrl}/-/commit/${this.error.lastReleaseVersion}`;
    },
    shortFirstReleaseVersion() {
      return this.error.firstReleaseVersion.substr(0, 10);
    },
    shortLastReleaseVersion() {
      return this.error.lastReleaseVersion.substr(0, 10);
    },
    shortGitlabCommit() {
      return this.error.gitlabCommit.substr(0, 10);
    },
  },
  methods: {
    trackClickErrorLinkToSentryOptions,
  },
  CARD_CLASS,
  HEADER_CLASS,
  BODY_CLASS,
};
</script>

<template>
  <div>
    <div
      v-if="error"
      class="gl-display-flex gl-flex-wrap gl-justify-content-center gl-my-7 gl-row-gap-6"
    >
      <gl-card
        :class="$options.CARD_CLASS"
        :body-class="$options.BODY_CLASS"
        :header-class="$options.HEADER_CLASS"
        data-testid="error-count-card"
      >
        <template #header>
          <span>{{ __('Events') }}</span>
        </template>

        <template #default>
          <span>{{ error.count }}</span>
        </template>
      </gl-card>

      <gl-card
        :class="$options.CARD_CLASS"
        :body-class="$options.BODY_CLASS"
        :header-class="$options.HEADER_CLASS"
        data-testid="user-count-card"
      >
        <template #header>
          <span>{{ __('Users') }}</span>
        </template>

        <template #default>
          <span>{{ error.userCount }}</span>
        </template>
      </gl-card>

      <gl-card
        v-if="error.firstReleaseVersion"
        :class="$options.CARD_CLASS"
        :body-class="$options.BODY_CLASS"
        :header-class="$options.HEADER_CLASS"
        data-testid="first-release-card"
      >
        <template #header>
          <gl-icon v-gl-tooltip :title="shortFirstReleaseVersion" name="commit" class="gl-mr-1" />
          <span>{{ __('First seen') }}</span>
        </template>

        <template #default>
          <gl-link v-if="error.integrated" :href="firstCommitLink" class="gl-font-lg">
            <time-ago-tooltip :time="error.firstSeen" />
          </gl-link>

          <gl-link v-else :href="firstReleaseLink" target="_blank" class="gl-font-lg">
            <time-ago-tooltip :time="error.firstSeen" />
          </gl-link>
        </template>
      </gl-card>

      <gl-card
        v-if="error.lastReleaseVersion"
        :class="$options.CARD_CLASS"
        :body-class="$options.BODY_CLASS"
        :header-class="$options.HEADER_CLASS"
        data-testid="last-release-card"
      >
        <template #header>
          <gl-icon v-gl-tooltip :title="shortLastReleaseVersion" name="commit" class="gl-mr-1" />
          {{ __('Last seen') }}
        </template>

        <template #default>
          <gl-link v-if="error.integrated" :href="lastCommitLink" class="gl-font-lg">
            <time-ago-tooltip :time="error.lastSeen" />
          </gl-link>
          <gl-link v-else :href="lastReleaseLink" target="_blank" class="gl-font-lg">
            <time-ago-tooltip :time="error.lastSeen" />
          </gl-link>
        </template>
      </gl-card>

      <gl-card
        v-if="error.gitlabCommit"
        :class="$options.CARD_CLASS"
        :body-class="$options.BODY_CLASS"
        :header-class="$options.HEADER_CLASS"
        data-testid="gitlab-commit-card"
      >
        <template #header>
          {{ __('GitLab commit') }}
        </template>

        <template #default>
          <gl-link :href="error.gitlabCommitPath" class="gl-font-lg">
            {{ shortGitlabCommit }}
          </gl-link>
        </template>
      </gl-card>
    </div>
    <div v-if="!error.integrated" class="py-3">
      <span class="gl-font-weight-bold">{{ __('Sentry event') }}:</span>
      <gl-link
        v-track-event="trackClickErrorLinkToSentryOptions(error.externalUrl)"
        :href="error.externalUrl"
        target="_blank"
        data-testid="external-url-link"
      >
        <span class="text-truncate">{{ error.externalUrl }}</span>
        <gl-icon name="external-link" class="ml-1 flex-shrink-0" />
      </gl-link>
    </div>
  </div>
</template>
