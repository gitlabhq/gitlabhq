<script>
import { GlCollapsibleListbox, GlAvatarLabeled } from '@gitlab/ui';
import { __ } from '~/locale';
import { getIdFromGraphQLId, isGid } from '~/graphql_shared/utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export default {
  components: {
    GlCollapsibleListbox,
    GlAvatarLabeled,
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
  data() {
    return {
      selected: this.selectedProject,
    };
  },
  computed: {
    dropdownText() {
      return this.selectedProject
        ? this.selectedProject.name_with_namespace
        : this.projectDropdownText;
    },
    items() {
      const items = this.projects.map((project) => {
        return {
          value: project.id,
          ...project,
        };
      });

      return convertObjectPropsToCamelCase(items, { deep: true });
    },
  },
  methods: {
    getEntityId(project) {
      return isGid(project.id) ? getIdFromGraphQLId(project.id) : project.id;
    },
    selectProject(projectId) {
      this.$emit(
        'project-selected',
        this.projects.find((project) => project.id === projectId),
      );
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    v-model="selected"
    block
    fluid-width
    is-check-centered
    :toggle-text="dropdownText"
    :items="items"
    @select="selectProject"
  >
    <template #list-item="{ item }">
      <gl-avatar-labeled
        :label="item.nameWithNamespace"
        :entity-name="item.nameWithNamespace"
        :entity-id="getEntityId(item)"
        shape="rect"
        :size="32"
        :src="item.avatarUrl"
      />
    </template>
  </gl-collapsible-listbox>
</template>
