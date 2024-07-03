<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { __ } from '~/locale';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import getGroupsAndProjectsQuery from '../graphql/queries/get_groups_and_projects.query.graphql';

export default {
  components: {
    GlCollapsibleListbox,
    ProjectAvatar,
  },
  props: {
    placeholder: {
      type: String,
      required: false,
      default: '',
    },
    isValid: {
      type: Boolean,
      required: false,
      default: true,
    },
    value: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      groupsAndProjects: { groups: [], projects: [] },
      search: '',
    };
  },
  apollo: {
    groupsAndProjects: {
      query: getGroupsAndProjectsQuery,
      variables() {
        return {
          search: this.search,
        };
      },
      update(data) {
        return {
          groups: data?.groups?.nodes,
          projects: data?.projects?.nodes,
        };
      },
    },
  },
  computed: {
    listboxItems() {
      const { groups = [], projects = [] } = this.groupsAndProjects;
      return [
        {
          text: __('Groups'),
          options: groups.map(this.setValueToFullPath),
        },
        {
          text: __('Projects'),
          options: projects.map(this.setValueToFullPath),
        },
      ];
    },
    loading() {
      return this.$apollo.queries.groupsAndProjects.loading;
    },
    toggleText() {
      if (!this.value) {
        return this.placeholder;
      }
      return this.value;
    },
  },
  methods: {
    onSelect(path) {
      this.$emit('select', path);
    },
    onSearch(query) {
      this.search = query;
    },
    setValueToFullPath(item) {
      return { ...item, value: item.fullPath };
    },
  },
};
</script>
<template>
  <gl-collapsible-listbox
    :items="listboxItems"
    :value="value"
    :selected="value"
    :toggle-text="toggleText"
    fluid-width
    block
    searchable
    is-check-centered
    :searching="loading"
    :toggle-class="{ 'gl-border-1! gl-border-red-500!': !isValid, 'gl-text-gray-500!': !value }"
    @select="onSelect"
    @search="onSearch"
  >
    <template #list-item="{ item: { id, name, avatarUrl, fullPath } }">
      <div class="gl-display-inline-flex gl-align-items-center">
        <project-avatar
          :alt="name"
          :project-avatar-url="avatarUrl"
          :project-id="id"
          :project-name="name"
          class="gl-mr-3"
        />
        <span>{{ fullPath }}</span>
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
