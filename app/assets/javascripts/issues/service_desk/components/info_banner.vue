<script>
import { GlLink, GlButton } from '@gitlab/ui';
import {
  infoBannerTitle,
  infoBannerAdminNote,
  infoBannerUserNote,
  enableServiceDesk,
  learnMore,
} from '../constants';

export default {
  name: 'InfoBanner',
  components: {
    GlLink,
    GlButton,
  },
  inject: [
    'serviceDeskCalloutSvgPath',
    'serviceDeskEmailAddress',
    'canAdminIssues',
    'canEditProjectSettings',
    'serviceDeskSettingsPath',
    'isServiceDeskEnabled',
    'serviceDeskHelpPath',
  ],
  i18n: { infoBannerTitle, infoBannerAdminNote, infoBannerUserNote, enableServiceDesk, learnMore },
  computed: {
    canSeeEmailAddress() {
      return this.canAdminIssues && this.isServiceDeskEnabled;
    },
    canEnableServiceDesk() {
      return this.canEditProjectSettings && !this.isServiceDeskEnabled;
    },
  },
};
</script>

<template>
  <div class="gl-border-b gl-pb-3 gl-display-flex gl-align-items-flex-start">
    <!-- eslint-disable @gitlab/vue-require-i18n-attribute-strings -->
    <img
      :src="serviceDeskCalloutSvgPath"
      alt=""
      class="gl-display-none gl-sm-display-block gl-p-5"
    />
    <!-- eslint-enable @gitlab/vue-require-i18n-attribute-strings -->
    <div class="gl-mt-3 gl-ml-3">
      <h5>{{ $options.i18n.infoBannerTitle }}</h5>
      <p v-if="canSeeEmailAddress">
        {{ $options.i18n.infoBannerAdminNote }} <code>{{ serviceDeskEmailAddress }}</code>
      </p>
      <p>
        {{ $options.i18n.infoBannerUserNote }}
        <gl-link :href="serviceDeskHelpPath">{{ $options.i18n.learnMore }}</gl-link
        >.
      </p>
      <p v-if="canEnableServiceDesk" class="gl-mt-3">
        <gl-button :href="serviceDeskSettingsPath" variant="confirm">{{
          $options.i18n.enableServiceDesk
        }}</gl-button>
      </p>
    </div>
  </div>
</template>
