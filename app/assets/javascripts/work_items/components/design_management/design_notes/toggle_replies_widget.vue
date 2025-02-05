<script>
import { GlButton, GlAvatar, GlAvatarLink, GlAvatarsInline, GlTooltipDirective } from '@gitlab/ui';
import { __, n__ } from '~/locale';

export default {
  name: 'ToggleNotesWidget',
  components: {
    GlButton,
    GlAvatar,
    GlAvatarLink,
    GlAvatarsInline,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
    iconName() {
      return this.collapsed ? 'chevron-right' : 'chevron-down';
    },
    toggleText() {
      return this.collapsed
        ? n__('%d reply', '%d replies', this.replies.length)
        : __('Collapse replies');
    },
    toggleTextColor() {
      return this.collapsed ? 'gl-text-link' : 'gl-text-default';
    },
    authors() {
      return [...new Set(this.replies.map((item) => item.author))];
    },
    authorCollapsedTooltip() {
      if (this.authors.length > 2) {
        return n__('%d reply', '%d replies', this.authors.length);
      }
      return '';
    },
    ariaState() {
      return String(!this.collapsed);
    },
  },
};
</script>

<template>
  <li
    class="toggle-comments gl-flex gl-min-h-8 gl-items-center gl-rounded-bl-base gl-rounded-br-base gl-bg-subtle gl-p-3"
    :class="{ expanded: !collapsed }"
    :aria-expanded="ariaState"
    data-testid="toggle-comments-wrapper"
  >
    <gl-button
      category="tertiary"
      data-testid="toggle-replies-button"
      class="gl-my-2 gl-mr-3 !gl-p-0"
      :icon="iconName"
      :aria-label="toggleText"
      @click="$emit('toggle')"
    />
    <template v-if="collapsed">
      <gl-avatars-inline
        v-if="authors.length"
        :avatars="authors"
        collapsed
        :max-visible="2"
        :avatar-size="24"
        badge-tooltip-prop="name"
        :badge-sr-only-text="authorCollapsedTooltip"
        class="gl-mr-3 gl-whitespace-nowrap"
      >
        <template #avatar="{ avatar }">
          <gl-avatar-link v-gl-tooltip :href="avatar.webUrl" :title="avatar.name">
            <gl-avatar :alt="avatar.name" :src="avatar.avatarUrl" :size="24" />
          </gl-avatar-link>
        </template>
      </gl-avatars-inline>
    </template>
    <gl-button
      variant="link"
      data-testid="replies-button"
      class="toggle-comments-button"
      @click="$emit('toggle')"
    >
      <span :class="toggleTextColor">{{ toggleText }}</span>
    </gl-button>
  </li>
</template>
