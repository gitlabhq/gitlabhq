<script>
import { GlCard } from '@gitlab/ui';
import RepoDropdown from './repo_dropdown.vue';
import RevisionDropdown from './revision_dropdown.vue';

export default {
  components: {
    RepoDropdown,
    RevisionDropdown,
    GlCard,
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
  <gl-card header-class="gl-py-2 gl-px-3 gl-font-weight-bold" body-class="gl-px-3">
    <template #header>
      {{ s__(`CompareRevisions|${revisionText}`) }}
    </template>
    <div class="gl-sm-display-flex gl-align-items-center">
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
  </gl-card>
</template>
