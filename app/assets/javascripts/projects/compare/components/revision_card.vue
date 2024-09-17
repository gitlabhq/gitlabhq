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
  <div class="revision-card gl-min-w-0 gl-basis-1/2">
    <h2 class="gl-mt-0 gl-text-base">
      {{ revisionText }}
    </h2>
    <div class="gl-flex gl-flex-col gl-gap-3 sm:gl-flex-row">
      <repo-dropdown
        class="gl-min-w-0 gl-max-w-full gl-basis-1/2"
        :params-name="paramsName"
        :projects="projects"
        :selected-project="selectedProject"
        v-on="$listeners"
      />
      <revision-dropdown
        class="gl-min-w-0 gl-max-w-full gl-basis-1/2"
        :refs-project-path="refsProjectPath"
        :params-name="paramsName"
        :params-branch="paramsBranch"
        v-on="$listeners"
      />
    </div>
  </div>
</template>
