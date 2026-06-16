<script>
import { GlAvatarLink } from '@gitlab/ui';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';

export default {
  name: 'ProjectPresenter',
  components: {
    GlAvatarLink,
    ProjectAvatar,
  },
  props: {
    data: {
      required: true,
      type: Object,
    },
  },
  computed: {
    projectName() {
      return this.data.name || this.data.nameWithNamespace || this.data.fullPath;
    },
    tooltipLabel() {
      return this.data.nameWithNamespace || this.data.fullPath || this.data.name;
    },
  },
};
</script>
<template>
  <gl-avatar-link
    :href="data.webPath"
    :title="tooltipLabel"
    class="gl-inline-flex gl-items-center gl-gap-3"
  >
    <project-avatar
      :project-id="data.id"
      :project-name="projectName"
      :project-avatar-url="data.avatarUrl"
      :size="24"
      :alt="''"
    />
    <span>{{ projectName }}</span>
  </gl-avatar-link>
</template>
