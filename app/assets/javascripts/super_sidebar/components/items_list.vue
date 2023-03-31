<script>
import { GlIcon, GlButton, GlTooltipDirective } from '@gitlab/ui';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import NavItem from './nav_item.vue';

export default {
  components: {
    GlIcon,
    GlButton,
    ProjectAvatar,
    NavItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    items: {
      type: Array,
      required: false,
      default: () => [],
    },
    editable: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <ul class="gl-p-0 gl-list-style-none">
    <nav-item
      v-for="item in items"
      :key="item.id"
      :item="item"
      :link-classes="{ 'gl-py-2!': true }"
    >
      <template #icon>
        <project-avatar
          :project-id="item.id"
          :project-name="item.title"
          :project-avatar-url="item.avatar"
          :size="24"
          aria-hidden="true"
        />
      </template>
      <template #actions>
        <gl-button
          v-if="editable"
          v-gl-tooltip.left
          size="small"
          category="tertiary"
          :aria-label="__('Remove')"
          :title="__('Remove')"
          class="gl-align-self-center gl-p-1! gl-absolute gl-right-4"
          data-testid="item-remove"
          @click.stop.prevent="$emit('remove-item', item)"
        >
          <gl-icon name="close" />
        </gl-button>
      </template>
    </nav-item>
    <slot name="view-all-items"></slot>
  </ul>
</template>
