<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { debounce, isNull } from 'lodash';

import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import { truncate } from '~/lib/utils/text_utility';
import searchNamespacesWhereUserCanImportProjectsQuery from '~/import_entities/import_projects/graphql/queries/search_namespaces_where_user_can_import_projects.query.graphql';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import { MINIMUM_SEARCH_LENGTH } from '~/graphql_shared/constants';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

// This is added outside the component as each dropdown on the page triggers a query,
// so if multiple queries fail, we only show 1 error.
const reportNamespaceLoadError = debounce(
  () =>
    createAlert({
      message: s__('ImportProjects|Requesting namespaces failed'),
    }),
  DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
);

export default {
  components: {
    GlCollapsibleListbox,
  },

  props: {
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    selected: {
      type: String,
      required: false,
      default: null,
    },
    toggleText: {
      type: String,
      required: false,
      default: null,
    },
    userNamespace: {
      type: String,
      required: false,
      default: undefined,
    },
  },

  MAX_IMPORT_TARGET_LENGTH: 24,

  data() {
    return {
      searchTerm: '',
    };
  },

  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    namespaces: {
      query: searchNamespacesWhereUserCanImportProjectsQuery,
      variables() {
        return {
          search: this.searchTerm,
        };
      },
      skip() {
        const hasNotEnoughSearchCharacters =
          this.searchTerm.length > 0 && this.searchTerm.length < MINIMUM_SEARCH_LENGTH;
        return hasNotEnoughSearchCharacters;
      },
      update(data) {
        return data.currentUser.groups.nodes;
      },
      error: reportNamespaceLoadError,
      debounce: DEBOUNCE_DELAY,
    },
  },

  computed: {
    isProject() {
      return Boolean(this.userNamespace);
    },

    filteredNamespaces() {
      return (this.namespaces ?? []).filter((ns) =>
        ns.fullPath.toLowerCase().includes(this.searchTerm.toLowerCase()),
      );
    },

    listboxToggleText() {
      if (isNull(this.selected)) {
        return this.toggleText;
      }

      return truncate(this.selected, this.$options.MAX_IMPORT_TARGET_LENGTH);
    },

    items() {
      return [
        this.isProject
          ? {
              text: __('Users'),
              options: [
                {
                  text: this.userNamespace,
                  value: this.userNamespace,
                },
              ],
            }
          : {
              text: __('Parent'),
              textSrOnly: true,
              options: [
                {
                  text: s__('BulkImport|No parent'),
                  value: '',
                },
              ],
            },
        {
          text: __('Groups'),
          options: this.filteredNamespaces.map((namespace) => {
            return {
              text: namespace.fullPath,
              value: namespace.fullPath,
            };
          }),
        },
      ];
    },
  },

  methods: {
    onSelect(value) {
      if (this.isProject) {
        this.$emit('select', value);
      } else if (value === '') {
        this.$emit('select', { fullPath: '', id: null });
      } else {
        const { fullPath, id } = this.filteredNamespaces.find((ns) => ns.fullPath === value);

        this.$emit('select', { fullPath, id });
      }
    },

    onSearch(value) {
      this.searchTerm = value.trim();
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    :items="items"
    :disabled="disabled"
    :selected="selected"
    :toggle-text="listboxToggleText"
    searchable
    fluid-width
    toggle-class="!gl-rounded-tr-none !gl-rounded-br-none"
    data-testid="target-namespace-dropdown"
    @select="onSelect"
    @search="onSearch"
  />
</template>
