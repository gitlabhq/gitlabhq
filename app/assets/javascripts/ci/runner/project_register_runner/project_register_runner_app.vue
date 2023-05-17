<script>
import { GlButton } from '@gitlab/ui';
import { getParameterByName, updateHistory, mergeUrlParams } from '~/lib/utils/url_utility';
import { PARAM_KEY_PLATFORM, DEFAULT_PLATFORM } from '../constants';
import RegistrationInstructions from '../components/registration/registration_instructions.vue';
import PlatformsDrawer from '../components/registration/platforms_drawer.vue';

export default {
  name: 'ProjectRegisterRunnerApp',
  components: {
    GlButton,
    RegistrationInstructions,
    PlatformsDrawer,
  },
  props: {
    runnerId: {
      type: String,
      required: true,
    },
    runnersPath: {
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
    <registration-instructions
      :runner-id="runnerId"
      :platform="platform"
      @toggleDrawer="onToggleDrawer"
    >
      <template #runner-list-name>{{ s__('Runners|Project › CI/CD Settings › Runners') }}</template>
    </registration-instructions>

    <platforms-drawer
      :platform="platform"
      :open="isDrawerOpen"
      @selectPlatform="onSelectPlatform"
      @close="onToggleDrawer(false)"
    />

    <gl-button :href="runnersPath" variant="confirm">{{
      s__('Runners|Go to runners page')
    }}</gl-button>
  </div>
</template>
