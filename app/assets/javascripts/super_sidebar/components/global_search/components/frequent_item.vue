<script>
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';

export default {
  name: 'FrequentlyVisitedItem',
  components: {
    ProjectAvatar,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center gl-gap-3">
    <project-avatar
      :project-id="item.id"
      :project-name="item.title"
      :project-avatar-url="item.avatar"
      :size="24"
      aria-hidden="true"
    />

    <div class="gl-flex-grow-1 gl-truncate-end">
      {{ item.title }}
      <div
        v-if="item.subtitle"
        data-testid="subtitle"
        class="gl-font-sm gl-text-gray-500 gl-truncate-end"
      >
        {{ item.subtitle }}
      </div>
    </div>
  </div>
</template>
