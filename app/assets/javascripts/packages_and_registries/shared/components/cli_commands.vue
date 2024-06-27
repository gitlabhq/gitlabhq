<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
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
} from '../constants';

const trackingLabel = 'quickstart_dropdown';

export default {
  components: {
    CodeInstruction,
    GlDisclosureDropdown,
  },
  mixins: [Tracking.mixin({ label: trackingLabel })],
  props: {
    dockerBuildCommand: {
      type: String,
      required: true,
    },
    dockerPushCommand: {
      type: String,
      required: true,
    },
    dockerLoginCommand: {
      type: String,
      required: true,
    },
  },
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
  <gl-disclosure-dropdown
    :toggle-text="$options.i18n.QUICK_START"
    variant="confirm"
    placement="bottom-end"
    @shown="track('click_dropdown')"
  >
    <div class="gl-px-3 gl-py-2">
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
    </div>
  </gl-disclosure-dropdown>
</template>
