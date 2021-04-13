<script>
import { GlDropdown, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';

const SOURCE_PARAM_NAME = 'to';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlSearchBoxByType,
  },
  inject: ['projectTo', 'projectsFrom'],
  props: {
    paramsName: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      searchTerm: '',
      selectedRepo: {},
    };
  },
  computed: {
    filteredRepos() {
      const lowerCaseSearchTerm = this.searchTerm.toLowerCase();

      return this?.projectsFrom.filter(({ name }) =>
        name.toLowerCase().includes(lowerCaseSearchTerm),
      );
    },
    isSourceRevision() {
      return this.paramsName === SOURCE_PARAM_NAME;
    },
    inputName() {
      return `${this.paramsName}_project_id`;
    },
  },
  mounted() {
    this.setDefaultRepo();
  },
  methods: {
    onClick(repo) {
      this.selectedRepo = repo;
      this.emitTargetProject(repo.name);
    },
    setDefaultRepo() {
      this.selectedRepo = this.projectTo;
    },
    emitTargetProject(name) {
      if (!this.isSourceRevision) {
        this.$emit('changeTargetProject', name);
      }
    },
  },
};
</script>

<template>
  <div>
    <input type="hidden" :name="inputName" :value="selectedRepo.id" />
    <gl-dropdown
      :text="selectedRepo.name"
      :header-text="s__(`CompareRevisions|Select target project`)"
      class="gl-w-full gl-font-monospace gl-sm-pr-3"
      toggle-class="gl-min-w-0"
      :disabled="isSourceRevision"
    >
      <template #header>
        <gl-search-box-by-type v-if="!isSourceRevision" v-model.trim="searchTerm" />
      </template>
      <template v-if="!isSourceRevision">
        <gl-dropdown-item
          v-for="repo in filteredRepos"
          :key="repo.id"
          is-check-item
          :is-checked="selectedRepo.id === repo.id"
          @click="onClick(repo)"
        >
          {{ repo.name }}
        </gl-dropdown-item>
      </template>
    </gl-dropdown>
  </div>
</template>
