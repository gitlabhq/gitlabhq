<script>
import { GlDropdown } from '@gitlab/ui';
import { __ } from '~/locale';

import ProjectListItem from '~/vue_shared/components/project_selector/project_list_item.vue';

export default {
  components: {
    GlDropdown,
    ProjectListItem,
  },
  props: {
    projectDropdownText: {
      type: String,
      required: false,
      default: __('Select a project'),
    },
    projects: {
      type: Array,
      required: false,
      default: () => [],
    },
    selectedProject: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    dropdownText() {
      return this.selectedProject
        ? this.selectedProject.name_with_namespace
        : this.projectDropdownText;
    },
  },
  methods: {
    onClick(project) {
      this.$emit('project-selected', project);
      this.$refs.dropdown.hide(true);
    },
  },
};
</script>

<template>
  <gl-dropdown ref="dropdown" block :text="dropdownText" menu-class="gl-w-full!">
    <project-list-item
      v-for="project in projects"
      :key="project.id"
      :project="project"
      :selected="false"
      @click="onClick(project)"
    />
  </gl-dropdown>
</template>
