<script>
import { GlButton, GlCollapsibleListbox, GlIcon, GlSprintf } from '@gitlab/ui';
import { keyBy } from 'lodash';
import { createAlert } from '~/alert';
import {
  MINIMUM_SEARCH_LENGTH,
  TYPENAME_USER,
  TYPENAME_GROUP,
  TYPENAME_PROJECT,
} from '~/graphql_shared/constants';
import { s__, __, n__, sprintf } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import getUserGroupsAndProjects from '~/personal_access_tokens/graphql/get_user_groups_and_projects.query.graphql';

export default {
  name: 'PersonalAccessTokenNamespaceSelector',
  components: {
    GlButton,
    GlCollapsibleListbox,
    CrudComponent,
    GlIcon,
    GlSprintf,
  },
  props: {
    error: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['input'],
  apollo: {
    groupsAndProjects: {
      query: getUserGroupsAndProjects,
      variables() {
        return {
          id: convertToGraphQLId(TYPENAME_USER, gon.current_user_id),
          search: this.searchTerm,
        };
      },
      skip() {
        const { length } = this.searchTerm;
        return length > 0 && length < MINIMUM_SEARCH_LENGTH;
      },
      update(data) {
        return {
          projects: data?.projects?.nodes || [],
          groups: data?.user?.groups?.nodes || [],
        };
      },
      error(error) {
        createAlert({
          message: this.$options.i18n.fetchError,
          captureError: true,
          error,
        });
      },
      debounce: DEBOUNCE_DELAY,
    },
  },
  data() {
    return {
      groupsAndProjects: { groups: [], projects: [] },
      searchTerm: '',
      selectedIds: [],
      selectedItems: [],
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.groupsAndProjects.loading;
    },
    projectsById() {
      return keyBy(this.groupsAndProjects.projects, 'id');
    },
    groupsById() {
      return keyBy(this.groupsAndProjects.groups, 'id');
    },
    itemsById() {
      return { ...this.projectsById, ...this.groupsById };
    },
    listboxItems() {
      const projectItems = this.groupsAndProjects.projects.map((p) => ({
        value: p.id,
        text: p.fullPath,
      }));

      const groupItems = this.groupsAndProjects.groups.map((g) => ({
        value: g.id,
        text: g.fullPath,
      }));

      return [
        {
          text: this.$options.i18n.groups,
          options: groupItems,
        },
        {
          text: this.$options.i18n.projects,
          options: projectItems,
        },
      ];
    },
    headerText() {
      return sprintf(this.$options.i18n.selected, { count: this.selectedIds.length });
    },
  },
  watch: {
    selectedIds(newIds, oldIds) {
      // items list changes as a user searches for groups / projects
      // hence store a list of selectedItems whenever selectedIds is updated
      this.updateSelectedItems(newIds, oldIds);
    },
  },
  methods: {
    updateSelectedItems(newIds, oldIds) {
      const addedIds = newIds.filter((id) => !oldIds.includes(id));

      // Add new objects to selectedObjects
      addedIds.forEach((id) => {
        const obj = this.itemsById[id];
        if (obj && !this.selectedItems.find((item) => item.id === id)) {
          this.selectedItems.push(obj);
        }
      });

      // Remove objects that are no longer selected
      this.selectedItems = this.selectedItems.filter((obj) => newIds.includes(obj.id));
    },
    onSearch(searchTerm) {
      this.searchTerm = searchTerm;
    },
    removeNamespace(namespaceId) {
      this.selectedIds = this.selectedIds.filter((item) => item !== namespaceId);

      this.$emit('input', this.selectedIds);
    },
    isGroup(item) {
      // eslint-disable-next-line no-underscore-dangle
      return item.__typename === TYPENAME_GROUP;
    },
    namespaceIcon(item) {
      // eslint-disable-next-line no-underscore-dangle
      return item.__typename === TYPENAME_PROJECT ? 'project' : 'group';
    },
    removeNamespaceAriaLabel(item) {
      const label = this.isGroup(item)
        ? this.$options.i18n.removeGroup
        : this.$options.i18n.removeProject;

      return sprintf(label, { name: item.name });
    },
  },
  i18n: {
    selected: __('%{count} selected'),
    noMatches: __('No matches found'),
    groups: __('Groups'),
    projects: __('Projects'),
    noNamespaces: s__('AccessTokens|No groups or projects added.'),
    searchPlaceholder: __('Search groups or projects'),
    addButton: s__('AccessTokens|Add group or project'),
    subGroupCount: n__('%{count} subgroup', '%{count} subgroups'),
    projectCount: n__('%{count} project', '%{count} projects'),
    removeGroup: s__('AccessTokens|Remove group %{name}'),
    removeProject: s__('AccessTokens|Remove project %{name}'),
    fetchError: s__('AccessTokens|Error loading groups and projects. Please refresh page.'),
  },
};
</script>

<template>
  <div>
    <crud-component class="gl-mt-0">
      <template #title>
        <gl-collapsible-listbox
          v-model="selectedIds"
          :items="listboxItems"
          :multiple="true"
          :header-text="headerText"
          :no-results-text="$options.i18n.noMatches"
          :searchable="true"
          :search-placeholder="$options.i18n.searchPlaceholder"
          :searching="isLoading"
          :toggle-text="$options.i18n.addButton"
          @search="onSearch"
          @select="$emit('input', $event)"
        />
      </template>

      <ul
        v-if="selectedIds.length"
        class="gl-flex gl-list-none gl-flex-col gl-gap-3 gl-pl-2"
        data-testid="selected-namespaces"
      >
        <li v-for="item in selectedItems" :key="item.id" class="gl-mb-2 gl-flex gl-items-center">
          <gl-icon :name="namespaceIcon(item)" />
          <div class="gl-ml-3">
            {{ item.fullPath }}

            <div v-if="isGroup(item)" class="gl-mt-2 gl-text-sm gl-text-subtle">
              <gl-sprintf :message="$options.i18n.subGroupCount">
                <template #count>{{ item.descendantGroupsCount }}</template> </gl-sprintf
              >,

              <gl-sprintf :message="$options.i18n.projectCount">
                <template #count>{{ item.projectsCount }}</template>
              </gl-sprintf>
            </div>
          </div>
          <gl-button
            icon="close"
            category="tertiary"
            class="gl-ml-auto"
            data-testid="remove-namespace"
            :aria-label="removeNamespaceAriaLabel(item)"
            @click="removeNamespace(item.id)"
          />
        </li>
      </ul>
      <div v-else class="gl-text-center">
        {{ $options.i18n.noNamespaces }}
      </div>
    </crud-component>

    <div v-if="error" class="gl-font-sm gl-mt-2 gl-text-red-500">
      {{ error }}
    </div>
  </div>
</template>
