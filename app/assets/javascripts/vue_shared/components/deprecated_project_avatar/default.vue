<script>
import Identicon from '../identicon.vue';
import ProjectAvatarImage from './image.vue';

export default {
  name: 'DeprecatedProjectAvatar',
  components: {
    Identicon,
    ProjectAvatarImage,
  },
  props: {
    project: {
      type: Object,
      required: true,
    },
    size: {
      type: Number,
      default: 40,
      required: false,
    },
  },
  computed: {
    sizeClass() {
      return `s${this.size}`;
    },
  },
};
</script>

<template>
  <span :class="sizeClass" class="avatar-container rect-avatar project-avatar">
    <project-avatar-image
      v-if="project.avatar_url"
      :link-href="project.path"
      :img-src="project.avatar_url"
      :img-alt="project.name"
      :img-size="size"
    />
    <identicon
      v-else
      :entity-id="project.id"
      :entity-name="project.name"
      :size-class="sizeClass"
      class="rect-avatar"
    />
  </span>
</template>
