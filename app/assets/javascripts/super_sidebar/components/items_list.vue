<script>
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import NavItem from './nav_item.vue';

export default {
  components: {
    ProjectAvatar,
    NavItem,
  },
  props: {
    items: {
      type: Array,
      required: false,
      default: () => [],
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
      is-subitem
    >
      <template #icon>
        <project-avatar
          :project-id="item.id"
          :project-name="item.title"
          :project-avatar-url="item.avatar"
          :size="24"
          aria-hidden="true"
          class="gl-mr-n2"
        />
      </template>
      <template #actions>
        <slot name="actions" :item="item"></slot>
      </template>
    </nav-item>
    <slot name="view-all-items"></slot>
  </ul>
</template>
