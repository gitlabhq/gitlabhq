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
  <div class="revision-card gl-flex-basis-half gl-min-w-0">
    <h2 class="gl-font-base gl-mt-0">
      {{ revisionText }}
    </h2>
    <div class="gl-flex gl-flex-direction-column gl-sm-flex-direction-row gl-gap-3">
      <repo-dropdown
        class="gl-flex-basis-half gl-min-w-0 gl-max-w-full"
        :params-name="paramsName"
        :projects="projects"
        :selected-project="selectedProject"
        v-on="$listeners"
      />
      <revision-dropdown
        class="gl-flex-basis-half gl-min-w-0 gl-max-w-full"
        :refs-project-path="refsProjectPath"
        :params-name="paramsName"
        :params-branch="paramsBranch"
        v-on="$listeners"
      />
    </div>
  </div>
</template>
