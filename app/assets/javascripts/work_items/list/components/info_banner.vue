<script>
import { GlLink, GlButton } from '@gitlab/ui';

export default {
  name: 'InfoBanner',
  components: {
    GlLink,
    GlButton,
  },
  inject: [
    'serviceDeskCalloutSvgPath',
    'serviceDeskEmailAddress',
    'canAdminIssue',
    'canAdminProject',
    'serviceDeskSettingsPath',
    'isServiceDeskEnabled',
    'serviceDeskHelpPath',
  ],
  computed: {
    canSeeEmailAddress() {
      return this.canAdminIssue && this.isServiceDeskEnabled;
    },
    canEnableServiceDesk() {
      return this.canAdminProject && !this.isServiceDeskEnabled;
    },
  },
};
</script>

<template>
  <div class="gl-border-b gl-flex gl-items-start gl-pb-3">
    <img :src="serviceDeskCalloutSvgPath" :alt="''" class="gl-hidden gl-p-5 @sm/panel:gl-block" />
    <div class="gl-ml-3 gl-mt-3">
      <p class="gl-mt-4 gl-font-bold">
        {{
          s__(
            'ServiceDesk|Use Service Desk to connect with your users and offer customer support through email right inside GitLab',
          )
        }}
      </p>
      <p v-if="canSeeEmailAddress">
        {{ s__('ServiceDesk|Your users can send emails to this address:') }}
        <code>{{ serviceDeskEmailAddress }}</code>
      </p>
      <p>
        {{
          s__(
            'ServiceDesk|Tickets created from Service Desk emails will appear here. Each comment becomes part of the email conversation.',
          )
        }}
        <gl-link :href="serviceDeskHelpPath">{{ __('Learn more about Service Desk') }}</gl-link
        >.
      </p>
      <p v-if="canEnableServiceDesk" class="gl-mt-3">
        <gl-button :href="serviceDeskSettingsPath" variant="confirm">
          {{ s__('ServiceDesk|Enable Service Desk') }}
        </gl-button>
      </p>
    </div>
  </div>
</template>
