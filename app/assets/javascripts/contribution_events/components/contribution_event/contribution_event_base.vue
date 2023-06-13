<script>
import { GlAvatarLabeled, GlAvatarLink, GlIcon } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: { GlAvatarLabeled, GlAvatarLink, GlIcon, TimeAgoTooltip },
  props: {
    event: {
      type: Object,
      required: true,
    },
    iconName: {
      type: String,
      required: true,
    },
    iconClass: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    author() {
      return this.event.author;
    },
    authorUsername() {
      return `@${this.author.username}`;
    },
  },
};
</script>

<template>
  <li class="gl-mt-5 gl-pb-5 gl-border-b gl-relative">
    <time-ago-tooltip :time="event.created_at" class="gl-float-right gl-text-secondary" />
    <gl-avatar-link :href="author.web_url">
      <gl-avatar-labeled
        :label="author.name"
        :sub-label="authorUsername"
        :src="author.avatar_url"
        :size="32"
      />
    </gl-avatar-link>
    <div class="gl-pl-8 gl-mt-2" data-testid="event-body">
      <div class="gl-text-secondary">
        <gl-icon :class="iconClass" :name="iconName" />
        <slot></slot>
      </div>
      <div v-if="$scopedSlots['additional-info']" class="gl-mt-2">
        <slot name="additional-info"></slot>
      </div>
    </div>
  </li>
</template>
