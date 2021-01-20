<script>
import { GlDropdown } from '@gitlab/ui';
import Tracking from '~/tracking';
import CodeInstruction from '~/vue_shared/components/registry/code_instruction.vue';
import {
  QUICK_START,
  LOGIN_COMMAND_LABEL,
  COPY_LOGIN_TITLE,
  BUILD_COMMAND_LABEL,
  COPY_BUILD_TITLE,
  PUSH_COMMAND_LABEL,
  COPY_PUSH_TITLE,
} from '../../constants/index';

const trackingLabel = 'quickstart_dropdown';

export default {
  components: {
    GlDropdown,
    CodeInstruction,
  },
  mixins: [Tracking.mixin({ label: trackingLabel })],
  inject: ['config', 'dockerBuildCommand', 'dockerPushCommand', 'dockerLoginCommand'],
  trackingLabel,
  i18n: {
    QUICK_START,
    LOGIN_COMMAND_LABEL,
    COPY_LOGIN_TITLE,
    BUILD_COMMAND_LABEL,
    COPY_BUILD_TITLE,
    PUSH_COMMAND_LABEL,
    COPY_PUSH_TITLE,
  },
};
</script>
<template>
  <gl-dropdown
    :text="$options.i18n.QUICK_START"
    variant="info"
    right
    @shown="track('click_dropdown')"
  >
    <!-- This li is used as a container since gl-dropdown produces a root ul, this mimics the functionality exposed by b-dropdown-form -->
    <li role="presentation" class="px-2 py-1">
      <code-instruction
        :label="$options.i18n.LOGIN_COMMAND_LABEL"
        :instruction="dockerLoginCommand"
        :copy-text="$options.i18n.COPY_LOGIN_TITLE"
        tracking-action="click_copy_login"
        :tracking-label="$options.trackingLabel"
      />

      <code-instruction
        :label="$options.i18n.BUILD_COMMAND_LABEL"
        :instruction="dockerBuildCommand"
        :copy-text="$options.i18n.COPY_BUILD_TITLE"
        tracking-action="click_copy_build"
        :tracking-label="$options.trackingLabel"
      />

      <code-instruction
        class="mb-0"
        :label="$options.i18n.PUSH_COMMAND_LABEL"
        :instruction="dockerPushCommand"
        :copy-text="$options.i18n.COPY_PUSH_TITLE"
        tracking-action="click_copy_push"
        :tracking-label="$options.trackingLabel"
      />
    </li>
  </gl-dropdown>
</template>
