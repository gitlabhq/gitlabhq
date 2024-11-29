<script>
import { GlAvatarLabeled, GlAvatarLink, GlIcon, GlSprintf } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import TargetLink from '../target_link.vue';
import ResourceParentLink from '../resource_parent_link.vue';

export default {
  components: {
    GlAvatarLabeled,
    GlAvatarLink,
    GlIcon,
    GlSprintf,
    TimeAgoTooltip,
    TargetLink,
    ResourceParentLink,
  },
  props: {
    event: {
      type: Object,
      required: true,
    },
    iconName: {
      type: String,
      required: true,
    },
    message: {
      type: String,
      required: false,
      default: '',
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
  <li class="gl-border-b gl-relative gl-mt-5 gl-flex gl-flex-col gl-pb-5">
    <div class="gl-flex gl-items-center">
      <gl-avatar-link :href="author.web_url" class="gl-grow">
        <gl-avatar-labeled
          :label="author.name"
          :sub-label="authorUsername"
          inline-labels
          :src="author.avatar_url"
          :size="24"
        />
      </gl-avatar-link>
      <time-ago-tooltip :time="event.created_at" class="gl-mt-2 gl-text-sm gl-text-subtle" />
    </div>
    <div class="gl-pl-7" data-testid="event-body">
      <div class="gl-text-sm gl-text-subtle">
        <gl-icon :name="iconName" />
        <gl-sprintf v-if="message" :message="message">
          <template #targetLink>
            <target-link :event="event" />
          </template>
          <template #resourceParentLink>
            <resource-parent-link :event="event" />
          </template>
        </gl-sprintf>
        <slot v-else></slot>
      </div>
      <div v-if="$scopedSlots['additional-info']" class="gl-mt-2">
        <slot name="additional-info"></slot>
      </div>
    </div>
  </li>
</template>
