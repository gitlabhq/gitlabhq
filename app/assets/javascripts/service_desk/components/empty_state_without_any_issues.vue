<script>
import { GlEmptyState, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
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
  serviceDeskHelpPagePath: helpPagePath('user/project/service_desk/index'),
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
      content-class="gl-max-w-80!"
    >
      <template #description>
        <p v-if="canSeeEmailAddress">
          {{ $options.i18n.infoBannerAdminNote }} <br /><code>{{ serviceDeskEmailAddress }}</code>
        </p>
        <p>{{ $options.i18n.infoBannerUserNote }}</p>
        <gl-link :href="$options.serviceDeskHelpPagePath" target="_blank">
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
    content-class="gl-max-w-80!"
  >
    <template #description>
      <p>{{ $options.i18n.infoBannerUserNote }}</p>
      <gl-link :href="$options.serviceDeskHelpPagePath">
        {{ $options.i18n.learnMore }}
      </gl-link>
    </template>
  </gl-empty-state>
</template>
