<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import dateFormat from 'dateformat';
import { __, sprintf } from '~/locale';
import { GlButton, GlLink, GlLoadingIcon } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import Stacktrace from './stacktrace.vue';
import TrackEventDirective from '~/vue_shared/directives/track_event';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { trackClickErrorLinkToSentryOptions } from '../utils';

export default {
  components: {
    GlButton,
    GlLink,
    GlLoadingIcon,
    TooltipOnTruncate,
    Icon,
    Stacktrace,
  },
  directives: {
    TrackEvent: TrackEventDirective,
  },
  mixins: [timeagoMixin],
  props: {
    issueDetailsPath: {
      type: String,
      required: true,
    },
    issueStackTracePath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState('details', ['error', 'loading', 'loadingStacktrace', 'stacktraceData']),
    ...mapGetters('details', ['stacktrace']),
    reported() {
      return sprintf(
        __('Reported %{timeAgo} by %{reportedBy}'),
        {
          reportedBy: `<strong>${this.error.culprit}</strong>`,
          timeAgo: this.timeFormated(this.stacktraceData.date_received),
        },
        false,
      );
    },
    firstReleaseLink() {
      return `${this.error.external_base_url}/releases/${this.error.first_release_short_version}`;
    },
    lastReleaseLink() {
      return `${this.error.external_base_url}releases/${this.error.last_release_short_version}`;
    },
    showDetails() {
      return Boolean(!this.loading && this.error && this.error.id);
    },
    showStacktrace() {
      return Boolean(!this.loadingStacktrace && this.stacktrace && this.stacktrace.length);
    },
  },
  mounted() {
    this.startPollingDetails(this.issueDetailsPath);
    this.startPollingStacktrace(this.issueStackTracePath);
  },
  methods: {
    ...mapActions('details', ['startPollingDetails', 'startPollingStacktrace']),
    trackClickErrorLinkToSentryOptions,
    formatDate(date) {
      return `${this.timeFormated(date)} (${dateFormat(date, 'UTC:yyyy-mm-dd h:MM:ssTT Z')})`;
    },
  },
};
</script>

<template>
  <div>
    <div v-if="loading" class="py-3">
      <gl-loading-icon :size="3" />
    </div>

    <div v-else-if="showDetails" class="error-details">
      <div class="top-area align-items-center justify-content-between py-3">
        <span v-if="!loadingStacktrace && stacktrace" v-html="reported"></span>
        <!--   <gl-button class="my-3 ml-auto" variant="success">
             {{ __('Create Issue') }}
           </gl-button>-->
      </div>
      <div>
        <tooltip-on-truncate :title="error.title" truncate-target="child" placement="top">
          <h2 class="text-truncate">{{ error.title }}</h2>
        </tooltip-on-truncate>
        <h3>{{ __('Error details') }}</h3>
        <ul>
          <li>
            <span class="bold">{{ __('Sentry event') }}:</span>
            <gl-link
              v-track-event="trackClickErrorLinkToSentryOptions(error.external_url)"
              :href="error.external_url"
              target="_blank"
            >
              <span class="text-truncate">{{ error.external_url }}</span>
              <icon name="external-link" class="ml-1 flex-shrink-0" />
            </gl-link>
          </li>
          <li v-if="error.first_release_short_version">
            <span class="bold">{{ __('First seen') }}:</span>
            {{ formatDate(error.first_seen) }}
            <gl-link :href="firstReleaseLink" target="_blank">
              <span>{{ __('Release') }}: {{ error.first_release_short_version }}</span>
            </gl-link>
          </li>
          <li v-if="error.last_release_short_version">
            <span class="bold">{{ __('Last seen') }}:</span>
            {{ formatDate(error.last_seen) }}
            <gl-link :href="lastReleaseLink" target="_blank">
              <span>{{ __('Release') }}: {{ error.last_release_short_version }}</span>
            </gl-link>
          </li>
          <li>
            <span class="bold">{{ __('Events') }}:</span>
            <span>{{ error.count }}</span>
          </li>
          <li>
            <span class="bold">{{ __('Users') }}:</span>
            <span>{{ error.user_count }}</span>
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
