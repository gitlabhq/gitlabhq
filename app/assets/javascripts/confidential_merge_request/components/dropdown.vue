<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlCollapsibleListbox,
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
    selectedProjectValue() {
      return this.selectedProject?.id && String(this.selectedProject.id);
    },
    toggleText() {
      return this.selectedProject?.name || __('Select private project');
    },
    listboxItems() {
      return this.projects.map(({ id, name }) => {
        return {
          value: String(id),
          text: name,
        };
      });
    },
  },
  methods: {
    selectProject(projectId) {
      const project = this.projects.find(({ id }) => String(id) === projectId);
      this.$emit('select', project);
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    icon="lock"
    :items="listboxItems"
    :selected="selectedProjectValue"
    :toggle-text="toggleText"
    block
    @select="selectProject"
  />
</template>
