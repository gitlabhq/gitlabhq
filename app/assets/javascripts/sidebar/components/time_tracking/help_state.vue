<script>
/* eslint-disable vue/no-v-html */
import { GlButton } from '@gitlab/ui';
import { joinPaths } from '~/lib/utils/url_utility';
import { sprintf, s__ } from '../../../locale';

export default {
  name: 'TimeTrackingHelpState',
  components: {
    GlButton,
  },
  computed: {
    href() {
      return joinPaths(gon.relative_url_root || '', '/help/user/project/time_tracking.md');
    },
    estimateText() {
      return sprintf(
        s__(
          'estimateCommand|%{slash_command} will update the estimated time with the latest command.',
        ),
        {
          slash_command: '<code>/estimate</code>',
        },
        false,
      );
    },
    spendText() {
      return sprintf(
        s__('spendCommand|%{slash_command} will update the sum of the time spent.'),
        {
          slash_command: '<code>/spend</code>',
        },
        false,
      );
    },
  },
};
</script>

<template>
  <div data-testid="helpPane" class="time-tracking-help-state">
    <div class="time-tracking-info">
      <h4>{{ __('Track time with quick actions') }}</h4>
      <p>{{ __('Quick actions can be used in the issues description and comment boxes.') }}</p>
      <p v-html="estimateText"></p>
      <p v-html="spendText"></p>
      <gl-button :href="href">{{ __('Learn more') }}</gl-button>
    </div>
  </div>
</template>
