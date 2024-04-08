<script>
import { GlButton } from '@gitlab/ui';
import { getParameterByName, updateHistory, mergeUrlParams } from '~/lib/utils/url_utility';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { PARAM_KEY_PLATFORM, DEFAULT_PLATFORM } from '../constants';
import RegistrationInstructions from '../components/registration/registration_instructions.vue';

export default {
  name: 'GroupRegisterRunnerApp',
  components: {
    GlButton,
    RegistrationInstructions,
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
  },
};
</script>
<template>
  <div>
    <registration-instructions
      :runner-id="runnerId"
      :group-path="groupPath"
      :platform="platform"
      @selectPlatform="onSelectPlatform"
    >
      <template #runner-list-name>{{ s__('Runners|Group area › Runners') }}</template>
    </registration-instructions>

    <gl-button
      :href="runnersPath"
      variant="confirm"
      data-event-tracking="click_view_runners_button_in_new_group_runner_form"
    >
      {{ s__('Runners|View runners') }}
    </gl-button>
  </div>
</template>
