<script>
import { GlIcon, GlButton, GlLink } from '@gitlab/ui';
import { __, n__ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'ToggleNotesWidget',
  components: {
    GlIcon,
    GlButton,
    GlLink,
    TimeAgoTooltip,
  },
  props: {
    collapsed: {
      type: Boolean,
      required: true,
    },
    replies: {
      type: Array,
      required: true,
    },
  },
  computed: {
    lastReply() {
      return this.replies[this.replies.length - 1];
    },
    iconName() {
      return this.collapsed ? 'chevron-right' : 'chevron-down';
    },
    toggleText() {
      return this.collapsed
        ? `${this.replies.length} ${n__('reply', 'replies', this.replies.length)}`
        : __('Collapse replies');
    },
  },
};
</script>

<template>
  <li
    class="toggle-comments gl-bg-gray-50 gl-display-flex gl-align-items-center gl-py-3"
    :class="{ expanded: !collapsed }"
    data-testid="toggle-comments-wrapper"
  >
    <gl-icon :name="iconName" class="gl-ml-3" @click.stop="$emit('toggle')" />
    <gl-button
      variant="link"
      class="toggle-comments-button gl-ml-2 gl-mr-2"
      @click.stop="$emit('toggle')"
    >
      {{ toggleText }}
    </gl-button>
    <template v-if="collapsed">
      <span class="gl-text-gray-700">{{ __('Last reply by') }}</span>
      <gl-link
        :href="lastReply.author.webUrl"
        target="_blank"
        class="link-inherit-color gl-text-black-normal gl-text-decoration-none gl-font-weight-bold gl-ml-2 gl-mr-2"
      >
        {{ lastReply.author.name }}
      </gl-link>
      <time-ago-tooltip
        :time="lastReply.createdAt"
        tooltip-placement="bottom"
        class="gl-text-gray-700"
      />
    </template>
  </li>
</template>
