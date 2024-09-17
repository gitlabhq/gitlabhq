<script>
import { GlButton, GlButtonGroup, GlCollapsibleListbox } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { MINIMUM_SEARCH_LENGTH } from '~/graphql_shared/constants';
import { s__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import searchForkableNamespaces from '../queries/search_forkable_namespaces.query.graphql';

export default {
  components: {
    GlButton,
    GlButtonGroup,
    GlCollapsibleListbox,
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
    loading() {
      return this.$apollo.queries.project.loading;
    },
    rootUrl() {
      return `${gon.gitlab_url}/`;
    },
    namespaces() {
      return this.project.forkTargets?.nodes || [];
    },
    dropdownText() {
      return this.selectedNamespace?.fullPath || s__('ForkProject|Select a namespace');
    },
    namespaceItems() {
      return this.namespaces?.map(({ id, fullPath }) => ({ value: id, text: fullPath }));
    },
  },
  methods: {
    setNamespace(namespaceId) {
      const namespace = this.namespaces.find(({ id }) => id === namespaceId);
      const id = getIdFromGraphQLId(namespace.id);

      this.$emit('select', {
        id,
        name: namespace.name,
        visibility: namespace.visibility,
      });

      this.selectedNamespace = { id, fullPath: namespace.fullPath };
    },
    searchNamespaces(search) {
      this.search = search;
    },
  },
};
</script>

<template>
  <gl-button-group class="gl-w-full">
    <gl-button class="gl-max-w-34 !gl-grow-0 gl-truncate" label :title="rootUrl">{{
      rootUrl
    }}</gl-button>
    <gl-collapsible-listbox
      class="gl-grow"
      data-testid="select-namespace-dropdown"
      :items="namespaceItems"
      :header-text="__('Namespaces')"
      :no-results-text="__('No matches found')"
      :searchable="true"
      :searching="loading"
      toggle-class="gl-flex-col !gl-items-stretch !gl-rounded-tl-none !gl-rounded-bl-none !gl-w-full"
      :toggle-text="dropdownText"
      @search="searchNamespaces"
      @select="setNamespace"
    />
  </gl-button-group>
</template>
