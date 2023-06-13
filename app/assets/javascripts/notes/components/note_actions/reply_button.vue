<script>
import { GlTooltipDirective, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  i18n: {
    buttonText: __('Reply to comment'),
  },
  name: 'ReplyButton',
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip
    data-track-action="click_button"
    data-track-label="reply_comment_button"
    category="tertiary"
    icon="reply"
    :title="$options.i18n.buttonText"
    :aria-label="$options.i18n.buttonText"
    @click="$emit('startReplying')"
  />
</template>
