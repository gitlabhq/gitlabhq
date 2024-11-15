<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { getDisplayName } from '../utils';

export default {
  components: {
    GlCollapsibleListbox,
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
  computed: {
    listboxItems() {
      return this.projects.map((project) => {
        return {
          text: getDisplayName(project),
          value: project.id,
        };
      });
    },
  },
  methods: {
    selectProject(id) {
      const project = this.projects.find((p) => p.id === id);
      this.$emit('select-project', project);
    },
  },
};
</script>

<template>
  <div :class="{ 'gl-show-field-errors': isProjectInvalid }">
    <label class="label-bold" for="project-dropdown">{{ __('Project') }}</label>
    <div class="row">
      <gl-collapsible-listbox
        id="project-dropdown"
        class="gl-pl-5"
        :disabled="!hasProjects"
        :items="listboxItems"
        :selected="selectedProject && selectedProject.id"
        :toggle-text="dropdownLabel"
        @select="selectProject"
      />
    </div>
    <p v-if="isProjectInvalid" class="js-project-dropdown-error gl-field-error">
      {{ invalidProjectLabel }}
    </p>
    <p v-else-if="!hasProjects" class="js-project-dropdown-label form-text gl-text-subtle">
      {{ projectSelectionLabel }}
    </p>
  </div>
</template>
