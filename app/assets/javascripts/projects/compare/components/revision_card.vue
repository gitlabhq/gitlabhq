<script>
import RepoDropdown from './repo_dropdown.vue';
import RevisionDropdown from './revision_dropdown.vue';

export default {
  components: {
    RepoDropdown,
    RevisionDropdown,
  },
  props: {
    refsProjectPath: {
      type: String,
      required: true,
    },
    revisionText: {
      type: String,
      required: true,
    },
    paramsName: {
      type: String,
      required: true,
    },
    paramsBranch: {
      type: String,
      required: false,
      default: null,
    },
    projects: {
      type: Array,
      required: false,
      default: null,
    },
    selectedProject: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div class="revision-card gl-flex-basis-half">
    <h2 class="gl-font-base gl-mt-0">
      {{ revisionText }}
    </h2>
    <div class="gl-sm-display-flex gl-align-items-center gl-gap-3">
      <repo-dropdown
        class="gl-sm-w-half"
        :params-name="paramsName"
        :projects="projects"
        :selected-project="selectedProject"
        v-on="$listeners"
      />
      <revision-dropdown
        class="gl-sm-w-half gl-mt-3 gl-sm-mt-0"
        :refs-project-path="refsProjectPath"
        :params-name="paramsName"
        :params-branch="paramsBranch"
        v-on="$listeners"
      />
    </div>
  </div>
</template>
