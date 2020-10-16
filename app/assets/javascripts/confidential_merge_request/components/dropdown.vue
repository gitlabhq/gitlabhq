<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    projects: {
      type: Array,
      required: true,
    },
    selectedProject: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    dropdownText() {
      if (Object.keys(this.selectedProject).length) {
        return this.selectedProject.name;
      }

      return __('Select private project');
    },
  },
  methods: {
    selectProject(project) {
      this.$emit('click', project);
    },
  },
};
</script>

<template>
  <gl-dropdown block icon="lock" :text="dropdownText">
    <gl-dropdown-item
      v-for="project in projects"
      :key="project.id"
      :is-check-item="true"
      :is-checked="project.id === selectedProject.id"
      @click="selectProject(project)"
    >
      {{ project.name }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
