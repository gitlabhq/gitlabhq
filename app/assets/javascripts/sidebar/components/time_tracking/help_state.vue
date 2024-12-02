<script>
import { GlButton } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { joinPaths } from '~/lib/utils/url_utility';
import { sprintf, s__ } from '~/locale';

export default {
  name: 'TimeTrackingHelpState',
  components: {
    GlButton,
  },
  directives: {
    SafeHtml,
  },
  computed: {
    href() {
      return joinPaths(gon.relative_url_root || '', '/help/user/project/time_tracking.md');
    },
    estimateText() {
      return sprintf(
        s__('estimateCommand|%{slash_command} overwrites the total estimated time.'),
        {
          slash_command: '<code>/estimate</code>',
        },
        false,
      );
    },
    spendText() {
      return sprintf(
        s__('spendCommand|%{slash_command} adds or subtracts time already spent.'),
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
  <div
    data-testid="helpPane"
    class="sidebar-help-state gl-border-1 gl-border-default gl-bg-white gl-border-b-solid gl-border-t-solid"
  >
    <div class="time-tracking-info">
      <h4>{{ __('Track time with quick actions') }}</h4>
      <p>{{ __('Quick actions can be used in description and comment boxes.') }}</p>
      <p v-safe-html="estimateText"></p>
      <p v-safe-html="spendText"></p>
      <gl-button :href="href">{{ __('Learn more') }}</gl-button>
    </div>
  </div>
</template>
