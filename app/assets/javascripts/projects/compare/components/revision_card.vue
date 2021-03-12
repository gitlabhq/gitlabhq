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
  },
  data() {
    return {
      selectedRefsProjectPath: this.refsProjectPath,
    };
  },
  methods: {
    onChangeTargetProject(targetProjectName) {
      if (this.paramsName === 'from') {
        this.selectedRefsProjectPath = `/${targetProjectName}/refs`;
      }
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
        @changeTargetProject="onChangeTargetProject"
      />
      <revision-dropdown
        class="gl-sm-w-half gl-mt-3 gl-sm-mt-0"
        :refs-project-path="selectedRefsProjectPath"
        :params-name="paramsName"
        :params-branch="paramsBranch"
      />
    </div>
  </gl-card>
</template>
