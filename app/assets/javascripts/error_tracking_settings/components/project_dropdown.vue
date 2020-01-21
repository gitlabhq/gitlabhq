<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { getDisplayName } from '../utils';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    dropdownLabel: {
      type: String,
      required: true,
    },
    hasProjects: {
      type: Boolean,
      required: true,
    },
    invalidProjectLabel: {
      type: String,
      required: true,
    },
    isProjectInvalid: {
      type: Boolean,
      required: true,
    },
    projects: {
      type: Array,
      required: true,
    },
    selectedProject: {
      type: Object,
      required: false,
      default: null,
    },
    projectSelectionLabel: {
      type: String,
      required: true,
    },
    token: {
      type: String,
      required: true,
    },
  },
  methods: {
    getDisplayName,
  },
};
</script>

<template>
  <div :class="{ 'gl-show-field-errors': isProjectInvalid }">
    <label class="label-bold" for="project-dropdown">{{ __('Project') }}</label>
    <div class="row">
      <gl-dropdown
        id="project-dropdown"
        class="col-8 col-md-9 gl-pr-0"
        :disabled="!hasProjects"
        menu-class="w-100 mw-100"
        toggle-class="dropdown-menu-toggle w-100 gl-field-error-outline"
        :text="dropdownLabel"
      >
        <gl-dropdown-item
          v-for="project in projects"
          :key="`${project.organizationSlug}.${project.slug}`"
          class="w-100"
          @click="$emit('select-project', project)"
          >{{ getDisplayName(project) }}</gl-dropdown-item
        >
      </gl-dropdown>
    </div>
    <p v-if="isProjectInvalid" class="js-project-dropdown-error gl-field-error">
      {{ invalidProjectLabel }}
    </p>
    <p v-else-if="!hasProjects" class="js-project-dropdown-label form-text text-muted">
      {{ projectSelectionLabel }}
    </p>
  </div>
</template>
