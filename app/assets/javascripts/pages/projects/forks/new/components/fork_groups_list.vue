<script>
import { GlTabs, GlTab, GlLoadingIcon, GlSearchBoxByType } from '@gitlab/ui';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import ForkGroupsListItem from './fork_groups_list_item.vue';

export default {
  components: {
    GlTabs,
    GlTab,
    GlLoadingIcon,
    GlSearchBoxByType,
    ForkGroupsListItem,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      namespaces: null,
      filter: '',
    };
  },
  computed: {
    filteredNamespaces() {
      return this.namespaces.filter((n) =>
        n.name.toLowerCase().includes(this.filter.toLowerCase()),
      );
    },
  },

  mounted() {
    this.loadGroups();
  },

  methods: {
    loadGroups() {
      axios
        .get(this.endpoint)
        .then((response) => {
          this.namespaces = response.data.namespaces;
        })
        .catch(() =>
          createFlash({
            message: __('There was a problem fetching groups.'),
          }),
        );
    },
  },

  i18n: {
    searchPlaceholder: __('Search by name'),
  },
};
</script>
<template>
  <gl-tabs class="fork-groups">
    <gl-tab :title="__('Groups and subgroups')">
      <gl-loading-icon v-if="!namespaces" size="md" class="gl-mt-3" />
      <template v-else-if="namespaces.length === 0">
        <div class="gl-text-center">
          <div class="h5">{{ __('No available groups to fork the project.') }}</div>
          <p class="gl-mt-5">
            {{ __('You must have permission to create a project in a group before forking.') }}
          </p>
        </div>
      </template>
      <div v-else-if="filteredNamespaces.length === 0" class="gl-text-center gl-mt-3">
        {{ s__('GroupsTree|No groups matched your search') }}
      </div>
      <ul v-else class="groups-list group-list-tree">
        <fork-groups-list-item
          v-for="(namespace, index) in filteredNamespaces"
          :key="index"
          :group="namespace"
        />
      </ul>
    </gl-tab>
    <template #tabs-end>
      <gl-search-box-by-type
        v-if="namespaces && namespaces.length"
        v-model="filter"
        :placeholder="$options.i18n.searchPlaceholder"
        class="gl-align-self-center gl-ml-auto fork-filtered-search"
        data-qa-selector="fork_groups_list_search_field"
      />
    </template>
  </gl-tabs>
</template>
