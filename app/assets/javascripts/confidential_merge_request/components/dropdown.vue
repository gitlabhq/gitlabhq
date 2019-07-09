<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { __ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    Icon,
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
  <gl-dropdown toggle-class="d-flex align-items-center w-100" class="w-100">
    <template slot="button-content">
      <span class="str-truncated-100 mr-2">
        <icon name="lock" />
        {{ dropdownText }}
      </span>
      <icon name="chevron-down" class="ml-auto" />
    </template>
    <gl-dropdown-item v-for="project in projects" :key="project.id" @click="selectProject(project)">
      <icon
        name="mobile-issue-close"
        :class="{ icon: project.id !== selectedProject.id }"
        class="js-active-project-check"
      />
      <span class="ml-1">{{ project.name }}</span>
    </gl-dropdown-item>
  </gl-dropdown>
</template>
