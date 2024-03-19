<script>
import { GlButton } from '@gitlab/ui';
import { getParameterByName, updateHistory, mergeUrlParams } from '~/lib/utils/url_utility';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { PARAM_KEY_PLATFORM, DEFAULT_PLATFORM, GOOGLE_CLOUD_PLATFORM } from '../constants';
import RegistrationInstructions from '../components/registration/registration_instructions.vue';
import GoogleCloudRegistrationInstructions from '../components/registration/google_cloud_registration_instructions.vue';
import PlatformsDrawer from '../components/registration/platforms_drawer.vue';

export default {
  name: 'GroupRegisterRunnerApp',
  components: {
    GoogleCloudRegistrationInstructions,
    GlButton,
    RegistrationInstructions,
    PlatformsDrawer,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    runnerId: {
      type: String,
      required: true,
    },
    runnersPath: {
      type: String,
      required: true,
    },
    groupPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      platform: getParameterByName(PARAM_KEY_PLATFORM) || DEFAULT_PLATFORM,
      isDrawerOpen: false,
    };
  },
  computed: {
    showGoogleCloudRegistration() {
      return (
        this.glFeatures.googleCloudSupportFeatureFlag && this.platform === GOOGLE_CLOUD_PLATFORM
      );
    },
  },
  watch: {
    platform(platform) {
      updateHistory({
        url: mergeUrlParams({ [PARAM_KEY_PLATFORM]: platform }, window.location.href),
      });
    },
  },
  methods: {
    onSelectPlatform(platform) {
      this.platform = platform;
    },
    onToggleDrawer(val = !this.isDrawerOpen) {
      this.isDrawerOpen = val;
    },
  },
};
</script>
<template>
  <div>
    <template v-if="showGoogleCloudRegistration">
      <google-cloud-registration-instructions :runner-id="runnerId" :group-path="groupPath" />
    </template>
    <template v-else>
      <registration-instructions
        :runner-id="runnerId"
        :platform="platform"
        @toggleDrawer="onToggleDrawer"
      >
        <template #runner-list-name>{{ s__('Runners|Group area › Runners') }}</template>
      </registration-instructions>

      <platforms-drawer
        :platform="platform"
        :open="isDrawerOpen"
        @selectPlatform="onSelectPlatform"
        @close="onToggleDrawer(false)"
      />
    </template>

    <gl-button
      :href="runnersPath"
      variant="confirm"
      data-event-tracking="click_view_runners_button_in_new_group_runner_form"
    >
      {{ s__('Runners|View runners') }}
    </gl-button>
  </div>
</template>
