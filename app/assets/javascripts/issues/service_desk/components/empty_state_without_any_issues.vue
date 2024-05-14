<script>
import { GlEmptyState, GlLink } from '@gitlab/ui';
import {
  noIssuesSignedOutButtonText,
  infoBannerTitle,
  infoBannerUserNote,
  infoBannerAdminNote,
  learnMore,
} from '../constants';

export default {
  i18n: {
    noIssuesSignedOutButtonText,
    infoBannerTitle,
    infoBannerUserNote,
    infoBannerAdminNote,
    learnMore,
  },
  components: {
    GlEmptyState,
    GlLink,
  },
  inject: [
    'emptyStateSvgPath',
    'isSignedIn',
    'signInPath',
    'canAdminIssues',
    'isServiceDeskEnabled',
    'serviceDeskEmailAddress',
    'serviceDeskHelpPath',
  ],
  computed: {
    canSeeEmailAddress() {
      return this.canAdminIssues && this.isServiceDeskEnabled;
    },
  },
};
</script>

<template>
  <div v-if="isSignedIn">
    <gl-empty-state
      :title="$options.i18n.infoBannerTitle"
      :svg-path="emptyStateSvgPath"
      data-testid="issues-service-desk-empty-state"
    >
      <template #description>
        <p v-if="canSeeEmailAddress">
          {{ $options.i18n.infoBannerAdminNote }} <br /><code>{{ serviceDeskEmailAddress }}</code>
        </p>
        <p>{{ $options.i18n.infoBannerUserNote }}</p>
        <gl-link :href="serviceDeskHelpPath">
          {{ $options.i18n.learnMore }}
        </gl-link>
      </template>
    </gl-empty-state>
  </div>

  <gl-empty-state
    v-else
    :title="$options.i18n.infoBannerTitle"
    :svg-path="emptyStateSvgPath"
    :primary-button-text="$options.i18n.noIssuesSignedOutButtonText"
    :primary-button-link="signInPath"
    data-testid="issues-service-desk-empty-state"
  >
    <template #description>
      <p>{{ $options.i18n.infoBannerUserNote }}</p>
      <gl-link :href="serviceDeskHelpPath">
        {{ $options.i18n.learnMore }}
      </gl-link>
    </template>
  </gl-empty-state>
</template>
