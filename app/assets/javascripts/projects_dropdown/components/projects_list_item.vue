<script>
import identicon from '../../vue_shared/components/identicon.vue';

export default {
  components: {
    identicon,
  },
  props: {
    matcher: {
      type: String,
      required: false,
    },
    projectId: {
      type: Number,
      required: true,
    },
    projectName: {
      type: String,
      required: true,
    },
    namespace: {
      type: String,
      required: true,
    },
    webUrl: {
      type: String,
      required: true,
    },
    avatarUrl: {
      required: true,
      validator(value) {
        return value === null || typeof value === 'string';
      },
    },
  },
  computed: {
    hasAvatar() {
      return this.avatarUrl !== null;
    },
    highlightedProjectName() {
      if (this.matcher) {
        const matcherRegEx = new RegExp(this.matcher, 'gi');
        const matches = this.projectName.match(matcherRegEx);

        if (matches && matches.length > 0) {
          return this.projectName.replace(matches[0], `<b>${matches[0]}</b>`);
        }
      }
      return this.projectName;
    },
  },
};
</script>

<template>
  <li
    class="projects-list-item-container"
  >
    <a
      class="clearfix"
      :href="webUrl"
    >
      <div
        class="project-item-avatar-container"
      >
        <img
          v-if="hasAvatar"
          class="avatar s32"
          :src="avatarUrl"
        />
        <identicon
          v-else
          size-class="s32"
          :entity-id=projectId
          :entity-name="projectName"
        />
      </div>
      <div
        class="project-item-metadata-container"
      >
        <div
          class="project-title"
          :title="projectName"
          v-html="highlightedProjectName"
        >
        </div>
        <div
          class="project-namespace"
          :title="namespace"
        >
          {{namespace}}
        </div>
      </div>
    </a>
  </li>
</template>
