<script>
import {
  GlButton,
  GlButtonGroup,
  GlDropdown,
  GlDropdownItem,
  GlDropdownText,
  GlDropdownSectionHeader,
  GlSearchBoxByType,
  GlTruncate,
} from '@gitlab/ui';
import { createAlert } from '~/flash';
import { MINIMUM_SEARCH_LENGTH } from '~/graphql_shared/constants';
import { s__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import searchForkableNamespaces from '../queries/search_forkable_namespaces.query.graphql';

export default {
  components: {
    GlButton,
    GlButtonGroup,
    GlDropdown,
    GlDropdownItem,
    GlDropdownText,
    GlDropdownSectionHeader,
    GlSearchBoxByType,
    GlTruncate,
  },
  apollo: {
    project: {
      query: searchForkableNamespaces,
      variables() {
        return {
          projectPath: this.projectFullPath,
          search: this.search,
        };
      },
      skip() {
        const { length } = this.search;
        return length > 0 && length < MINIMUM_SEARCH_LENGTH;
      },
      error(error) {
        createAlert({
          message: s__(
            'ForkProject|Something went wrong while loading data. Please refresh the page to try again.',
          ),
          captureError: true,
          error,
        });
      },
      debounce: DEBOUNCE_DELAY,
    },
  },
  inject: ['projectFullPath'],
  data() {
    return {
      project: {},
      search: '',
      selectedNamespace: null,
    };
  },
  computed: {
    rootUrl() {
      return `${gon.gitlab_url}/`;
    },
    namespaces() {
      return this.project.forkTargets?.nodes || [];
    },
    hasMatches() {
      return this.namespaces.length;
    },
    dropdownText() {
      return this.selectedNamespace?.fullPath || s__('ForkProject|Select a namespace');
    },
  },
  methods: {
    handleDropdownShown() {
      this.$refs.search.focusInput();
    },
    setNamespace(namespace) {
      const id = getIdFromGraphQLId(namespace.id);

      this.$emit('select', {
        id,
        name: namespace.name,
        visibility: namespace.visibility,
      });

      this.selectedNamespace = { id, fullPath: namespace.fullPath };
    },
  },
};
</script>

<template>
  <gl-button-group class="gl-w-full">
    <gl-button class="gl-text-truncate gl-flex-grow-0! gl-max-w-34" label :title="rootUrl">{{
      rootUrl
    }}</gl-button>

    <gl-dropdown
      class="gl-flex-grow-1"
      toggle-class="gl-rounded-top-right-base! gl-rounded-bottom-right-base! gl-w-20"
      data-qa-selector="select_namespace_dropdown"
      data-testid="select_namespace_dropdown"
      no-flip
      @shown="handleDropdownShown"
    >
      <template #button-text>
        <gl-truncate :text="dropdownText" position="start" with-tooltip />
      </template>
      <gl-search-box-by-type
        ref="search"
        v-model.trim="search"
        :is-loading="$apollo.queries.project.loading"
        data-qa-selector="select_namespace_dropdown_search_field"
        data-testid="select_namespace_dropdown_search_field"
      />
      <template v-if="!$apollo.queries.project.loading">
        <template v-if="hasMatches">
          <gl-dropdown-section-header>{{ __('Namespaces') }}</gl-dropdown-section-header>
          <gl-dropdown-item
            v-for="namespace of namespaces"
            :key="namespace.id"
            data-qa-selector="select_namespace_dropdown_item"
            @click="setNamespace(namespace)"
          >
            {{ namespace.fullPath }}
          </gl-dropdown-item>
        </template>
        <gl-dropdown-text v-else>{{ __('No matches found') }}</gl-dropdown-text>
      </template>
    </gl-dropdown>
  </gl-button-group>
</template>
