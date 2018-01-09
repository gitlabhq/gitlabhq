<script>
  /* eslint-disable vue/require-default-prop, vue/require-prop-types */
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
      /**
       * Smartly truncates project namespace by doing two things;
       * 1. Only include Group names in path by removing project name
       * 2. Only include first and last group names in the path
       *    when namespace has more than 2 groups present
       *
       * First part (removal of project name from namespace) can be
       * done from backend but doing so involves migration of
       * existing project namespaces which is not wise thing to do.
       */
      truncatedNamespace() {
        const namespaceArr = this.namespace.split(' / ');
        namespaceArr.splice(-1, 1);
        let namespace = namespaceArr.join(' / ');

        if (namespaceArr.length > 2) {
          namespace = `${namespaceArr[0]} / ... / ${namespaceArr.pop()}`;
        }

        return namespace;
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
          :entity-id="projectId"
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
        >{{ truncatedNamespace }}</div>
      </div>
    </a>
  </li>
</template>
