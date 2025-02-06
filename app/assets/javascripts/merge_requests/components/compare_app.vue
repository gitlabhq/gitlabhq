<script>
import { GlLoadingIcon, GlIcon } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import axios from '~/lib/utils/axios_utils';
import CompareDropdown from '~/merge_requests/components/compare_dropdown.vue';

export default {
  components: {
    GlIcon,
    GlLoadingIcon,
    CompareDropdown,
  },
  directives: {
    SafeHtml,
  },
  inject: {
    projectsPath: {
      default: '',
    },
    branchCommitPath: {
      default: '',
    },
    currentProject: {
      default: () => ({}),
    },
    inputs: {
      default: () => ({}),
    },
    i18n: {
      default: () => ({}),
    },
    toggleClass: {
      default: () => ({}),
    },
    compareSide: {
      default: null,
    },
  },
  props: {
    currentBranch: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      selectedProject: this.currentProject,
      selectedBranch: this.currentBranch,
      loading: false,
      commitHtml: null,
    };
  },
  computed: {
    staticProjectData() {
      if (this.projectsPath) return undefined;

      return [this.currentProject];
    },
    showCommitBox() {
      return this.commitHtml || this.loading || !this.selectedBranch.value;
    },
  },
  watch: {
    currentBranch(newVal) {
      this.selectedBranch = newVal;
      this.fetchCommit();
    },
  },
  mounted() {
    this.fetchCommit();
  },
  methods: {
    selectProject(p) {
      this.selectedProject = p;
    },
    selectBranch(branch) {
      this.selectedBranch = branch;
      this.fetchCommit();
      this.$emit('select-branch', branch.value);
    },
    async fetchCommit() {
      if (!this.selectedBranch.value) return;

      this.loading = true;

      const { data } = await axios.get(this.branchCommitPath, {
        params: { target_project_id: this.selectedProject.value, ref: this.selectedBranch.value },
      });

      this.loading = false;
      this.commitHtml = data;
    },
  },
};
</script>

<template>
  <div>
    <div class="clearfix">
      <div class="merge-request-select gl-pl-0">
        <compare-dropdown
          :static-data="staticProjectData"
          :endpoint="projectsPath"
          :default="currentProject"
          :dropdown-header="i18n.projectHeaderText"
          :input-id="inputs.project.id"
          :input-name="inputs.project.name"
          :toggle-class="toggleClass.project"
          is-project
          @selected="selectProject"
        />
      </div>
      <div class="merge-request-select merge-request-branch-select gl-pr-0">
        <compare-dropdown
          :endpoint="selectedProject.refsUrl"
          :dropdown-header="i18n.branchHeaderText"
          :input-id="inputs.branch.id"
          :input-name="inputs.branch.name"
          :default="currentBranch"
          :toggle-class="toggleClass.branch"
          :data-qa-compare-side="compareSide"
          :disabled="disabled"
          data-testid="compare-dropdown"
          @selected="selectBranch"
        />
      </div>
    </div>
    <div v-if="showCommitBox" class="gl-my-4 gl-rounded-base gl-bg-strong" data-testid="commit-box">
      <gl-loading-icon v-if="loading" class="gl-py-3" />
      <template v-else>
        <div
          v-if="!selectedBranch.value"
          class="compare-commit-empty gl-flex gl-items-center gl-p-5"
        >
          <gl-icon name="branch" class="gl-mr-3" />
          {{ __('Select a branch to compare') }}
        </div>
        <ul v-safe-html="commitHtml" class="list-unstyled mr_source_commit"></ul>
      </template>
    </div>
  </div>
</template>
