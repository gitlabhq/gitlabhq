<script>
import { GlButton, GlCollapsibleListbox, GlIcon } from '@gitlab/ui';
import { keyBy } from 'lodash-es';
import { TYPENAME_GROUP, TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { s__, __, n__, sprintf } from '~/locale';
import CrudComponent from '~/vue_shared/components/crud_component.vue';

export default {
  name: 'GranularNamespaceSelector',
  components: {
    GlButton,
    GlCollapsibleListbox,
    CrudComponent,
    GlIcon,
  },
  props: {
    value: {
      type: Array,
      required: false,
      default: () => [],
    },
    groups: {
      type: Array,
      required: false,
      default: () => [],
    },
    projects: {
      type: Array,
      required: false,
      default: () => [],
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    error: {
      type: String,
      required: false,
      default: '',
    },
    title: {
      type: String,
      required: false,
      default() {
        return s__('AccessTokens|Group or project');
      },
    },
    searchHint: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['input', 'search'],
  computed: {
    selectedIds() {
      return this.value.map((item) => item.id);
    },
    itemsById() {
      return keyBy([...this.projects, ...this.groups], 'id');
    },
    listboxItems() {
      const projectItems = this.projects.map((p) => ({
        value: p.id,
        text: p.fullPath,
      }));

      const groupItems = this.groups.map((g) => ({
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
  methods: {
    onSelect(ids) {
      // The listbox only lists the current search results, so an item selected
      // during an earlier search is taken from the value instead.
      const items = ids
        .map((id) => this.value.find((item) => item.id === id) || this.itemsById[id])
        .filter(Boolean);

      this.$emit('input', items);
    },
    srOnlyResultsLabel(count) {
      const results = n__('%d result', '%d results', count);

      // The footer hint is not tied to the search input, so screen readers only hear it here
      return this.searchHint ? `${results}. ${this.searchHint}` : results;
    },
    removeNamespace(namespaceId) {
      this.$emit(
        'input',
        this.value.filter((item) => item.id !== namespaceId),
      );
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
    subGroupCount({ descendantGroupsCount }) {
      return sprintf(n__('%{count} subgroup', '%{count} subgroups', descendantGroupsCount), {
        count: descendantGroupsCount,
      });
    },
    projectCount({ projectsCount }) {
      return sprintf(n__('%{count} project', '%{count} projects', projectsCount), {
        count: projectsCount,
      });
    },
    hasDescendantsCount({ descendantGroupsCount, projectsCount }) {
      return descendantGroupsCount != null && projectsCount != null;
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
    removeGroup: s__('AccessTokens|Remove group %{name}'),
    removeProject: s__('AccessTokens|Remove project %{name}'),
  },
};
</script>

<template>
  <div>
    <crud-component :title="title" class="gl-mt-0">
      <template #actions>
        <gl-collapsible-listbox
          :selected="selectedIds"
          :items="listboxItems"
          :multiple="true"
          :header-text="headerText"
          :no-results-text="$options.i18n.noMatches"
          :searchable="true"
          :search-placeholder="$options.i18n.searchPlaceholder"
          :searching="isLoading"
          :toggle-text="$options.i18n.addButton"
          :sr-only-results-label="srOnlyResultsLabel"
          @select="onSelect"
          @search="$emit('search', $event)"
        >
          <template v-if="searchHint" #footer>
            <div
              class="gl-border-t gl-px-4 gl-py-3 gl-text-sm gl-text-subtle"
              data-testid="search-hint"
            >
              {{ searchHint }}
            </div>
          </template>
        </gl-collapsible-listbox>
      </template>

      <ul
        v-if="value.length"
        class="gl-mb-2 gl-flex gl-list-none gl-flex-col gl-gap-3 gl-pl-2"
        data-testid="selected-namespaces"
      >
        <li v-for="item in value" :key="item.id" class="gl-mt-2">
          <div class="gl-flex gl-items-center">
            <gl-icon :name="namespaceIcon(item)" />
            <span class="gl-ml-3">{{ item.fullPath }}</span>
            <gl-button
              icon="close"
              category="tertiary"
              class="gl-ml-auto"
              data-testid="remove-namespace"
              :aria-label="removeNamespaceAriaLabel(item)"
              @click="removeNamespace(item.id)"
            />
          </div>

          <div
            v-if="hasDescendantsCount(item)"
            class="gl-ml-6 gl-text-sm gl-text-subtle"
            data-testid="descendant-counts"
          >
            {{ subGroupCount(item) }}, {{ projectCount(item) }}
          </div>
        </li>
      </ul>
      <div v-else class="gl-text-center">
        {{ $options.i18n.noNamespaces }}
      </div>
    </crud-component>

    <div v-if="error" class="invalid-feedback gl-block">{{ error }}</div>
  </div>
</template>
