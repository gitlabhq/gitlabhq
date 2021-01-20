<script>
import { GlTabs, GlTab, GlLoadingIcon, GlPagination } from '@gitlab/ui';
import { s__ } from '~/locale';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { fetchGroups } from '~/jira_connect/api';
import { defaultPerPage } from '~/jira_connect/constants';
import GroupsListItem from './groups_list_item.vue';

export default {
  components: {
    GlTabs,
    GlTab,
    GlLoadingIcon,
    GlPagination,
    GroupsListItem,
  },
  inject: {
    groupsPath: {
      default: '',
    },
  },
  data() {
    return {
      groups: [],
      isLoading: false,
      page: 1,
      perPage: defaultPerPage,
      totalItems: 0,
    };
  },
  mounted() {
    this.loadGroups();
  },
  methods: {
    loadGroups() {
      this.isLoading = true;

      fetchGroups(this.groupsPath, {
        page: this.page,
        perPage: this.perPage,
      })
        .then((response) => {
          const { page, total } = parseIntPagination(normalizeHeaders(response.headers));
          this.page = page;
          this.totalItems = total;
          this.groups = response.data;
        })
        .catch(() => {
          // eslint-disable-next-line no-alert
          alert(s__('Integrations|Failed to load namespaces. Please try again.'));
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
  },
};
</script>

<template>
  <gl-tabs>
    <gl-tab :title="__('Groups and subgroups')" class="gl-pt-3">
      <gl-loading-icon v-if="isLoading" size="md" />
      <div v-else-if="groups.length === 0" class="gl-text-center">
        <h5>{{ s__('Integrations|No available namespaces.') }}</h5>
        <p class="gl-mt-5">
          {{
            s__('Integrations|You must have owner or maintainer permissions to link namespaces.')
          }}
        </p>
      </div>
      <ul v-else class="gl-list-style-none gl-pl-0">
        <groups-list-item v-for="group in groups" :key="group.id" :group="group" />
      </ul>

      <div class="gl-display-flex gl-justify-content-center gl-mt-5">
        <gl-pagination
          v-if="totalItems > perPage && groups.length > 0"
          v-model="page"
          class="gl-mb-0"
          :per-page="perPage"
          :total-items="totalItems"
          @input="loadGroups"
        />
      </div>
    </gl-tab>
  </gl-tabs>
</template>
