<script>
import emptyStateSvg from '@gitlab/svgs/dist/illustrations/empty-state/empty-service-desk-md.svg';
import { GlEmptyState, GlLink } from '@gitlab/ui';
import { isLoggedIn } from '~/lib/utils/common_utils';
import {
  noIssuesSignedOutButtonText,
  infoBannerTitle,
  infoBannerUserNote,
  infoBannerAdminNote,
  learnMore,
} from '../constants';

export default {
  emptyStateSvg,
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
    'signInPath',
    'canAdminIssue',
    'isServiceDeskEnabled',
    'serviceDeskEmailAddress',
    'serviceDeskHelpPath',
  ],
  data() {
    return {
      isLoggedIn: isLoggedIn(),
    };
  },
  computed: {
    canSeeEmailAddress() {
      return this.canAdminIssue && this.isServiceDeskEnabled;
    },
  },
};
</script>

<template>
  <div v-if="isLoggedIn">
    <gl-empty-state
      :title="$options.i18n.infoBannerTitle"
      :svg-path="$options.emptyStateSvg"
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
    :svg-path="$options.emptyStateSvg"
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
