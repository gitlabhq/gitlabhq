<script>
import { GlSprintf } from '@gitlab/ui';
import { duration } from '~/lib/utils/datetime/timeago_utility';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import {
  I18N_STATUS_POPOVER_TITLE,
  I18N_STATUS_POPOVER_NEVER_CONTACTED,
  I18N_STATUS_POPOVER_NEVER_CONTACTED_DESCRIPTION,
  I18N_STATUS_POPOVER_ONLINE,
  I18N_STATUS_POPOVER_ONLINE_DESCRIPTION,
  I18N_STATUS_POPOVER_OFFLINE,
  I18N_STATUS_POPOVER_OFFLINE_DESCRIPTION,
  I18N_STATUS_POPOVER_STALE,
  I18N_STATUS_POPOVER_STALE_DESCRIPTION,
} from '~/ci/runner/constants';

export default {
  name: 'RunnerStatusPopover',
  components: {
    GlSprintf,
    HelpPopover,
  },
  inject: ['onlineContactTimeoutSecs', 'staleTimeoutSecs'],
  computed: {
    onlineContactTimeoutDuration() {
      return duration(this.onlineContactTimeoutSecs * 1000);
    },
    staleTimeoutDuration() {
      return duration(this.staleTimeoutSecs * 1000);
    },
  },
  I18N_STATUS_POPOVER_TITLE,
  I18N_STATUS_POPOVER_NEVER_CONTACTED,
  I18N_STATUS_POPOVER_NEVER_CONTACTED_DESCRIPTION,
  I18N_STATUS_POPOVER_ONLINE,
  I18N_STATUS_POPOVER_ONLINE_DESCRIPTION,
  I18N_STATUS_POPOVER_OFFLINE,
  I18N_STATUS_POPOVER_OFFLINE_DESCRIPTION,
  I18N_STATUS_POPOVER_STALE,
  I18N_STATUS_POPOVER_STALE_DESCRIPTION,
};
</script>

<template>
  <help-popover>
    <template #title>{{ $options.I18N_STATUS_POPOVER_TITLE }}</template>

    <p class="gl-mb-0">
      <strong>{{ $options.I18N_STATUS_POPOVER_NEVER_CONTACTED }}</strong>
      <gl-sprintf :message="$options.I18N_STATUS_POPOVER_NEVER_CONTACTED_DESCRIPTION">
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
      </gl-sprintf>
    </p>
    <p class="gl-mb-0">
      <strong>{{ $options.I18N_STATUS_POPOVER_ONLINE }}</strong>
      <gl-sprintf :message="$options.I18N_STATUS_POPOVER_ONLINE_DESCRIPTION">
        <template #elapsedTime>{{ onlineContactTimeoutDuration }}</template>
      </gl-sprintf>
    </p>
    <p class="gl-mb-0">
      <strong>{{ $options.I18N_STATUS_POPOVER_OFFLINE }}</strong>
      <gl-sprintf :message="$options.I18N_STATUS_POPOVER_OFFLINE_DESCRIPTION">
        <template #elapsedTime>{{ onlineContactTimeoutDuration }}</template>
      </gl-sprintf>
    </p>
    <p class="gl-mb-0">
      <strong>{{ $options.I18N_STATUS_POPOVER_STALE }}</strong>
      <gl-sprintf :message="$options.I18N_STATUS_POPOVER_STALE_DESCRIPTION">
        <template #elapsedTime>{{ staleTimeoutDuration }}</template>
      </gl-sprintf>
    </p>
  </help-popover>
</template>
