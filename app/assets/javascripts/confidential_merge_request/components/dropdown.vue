<script>
import { GlDeprecatedDropdown, GlDeprecatedDropdownItem, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlDeprecatedDropdown,
    GlDeprecatedDropdownItem,
    GlIcon,
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
  <gl-deprecated-dropdown toggle-class="d-flex align-items-center w-100" class="w-100">
    <template #button-content>
      <span class="str-truncated-100 mr-2">
        <gl-icon name="lock" />
        {{ dropdownText }}
      </span>
      <gl-icon name="chevron-down" class="ml-auto" />
    </template>
    <gl-deprecated-dropdown-item
      v-for="project in projects"
      :key="project.id"
      @click="selectProject(project)"
    >
      <gl-icon
        name="mobile-issue-close"
        :class="{ icon: project.id !== selectedProject.id }"
        class="js-active-project-check"
      />
      <span class="ml-1">{{ project.name }}</span>
    </gl-deprecated-dropdown-item>
  </gl-deprecated-dropdown>
</template>
