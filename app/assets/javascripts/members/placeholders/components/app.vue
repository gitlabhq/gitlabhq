<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { GlBadge, GlTab, GlTabs } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__, sprintf } from '~/locale';

import importSourceUsersQuery from '../graphql/queries/import_source_users.query.graphql';
import PlaceholdersTable from './placeholders_table.vue';

const DEFAULT_PAGE_SIZE = 20;

export default {
  name: 'PlaceholdersTabApp',
  components: {
    GlBadge,
    GlTab,
    GlTabs,
    PlaceholdersTable,
  },
  inject: ['group'],

  data() {
    return {
      selectedTabIndex: 0,
      unassignedCount: null,
      reassignedCount: null,
      cursor: {
        before: null,
        after: null,
      },
    };
  },

  apollo: {
    sourceUsers: {
      query: importSourceUsersQuery,
      variables() {
        return {
          fullPath: this.group.path,
          ...this.cursor,
          [this.cursor.before ? 'last' : 'first']: DEFAULT_PAGE_SIZE,
        };
      },
      update(data) {
        return data.namespace?.importSourceUsers;
      },
      error() {
        createAlert({
          message: s__('UserMapping|There was a problem fetching placeholder users.'),
        });
      },
    },
  },

  computed: {
    ...mapState('placeholder', ['pagination']),
    isLoading() {
      return Boolean(this.$apollo.queries.sourceUsers.loading);
    },
    nodes() {
      return this.sourceUsers?.nodes || [];
    },
    pageInfo() {
      return this.sourceUsers?.pageInfo || {};
    },
  },

  mounted() {
    this.unassignedCount = this.pagination.awaitingReassignmentItems;
    this.reassignedCount = this.pagination.reassignedItems;
  },

  methods: {
    onConfirm(item) {
      this.$toast.show(
        sprintf(s__('UserMapping|Placeholder %{name} (@%{username}) kept as placeholder.'), {
          name: item.placeholderUser.name,
          username: item.placeholderUser.username,
        }),
      );
      this.reassignedCount += 1;
      this.unassignedCount -= 1;
    },

    onPrevPage() {
      this.cursor = {
        before: this.sourceUsers.pageInfo.startCursor,
        after: null,
      };
    },

    onNextPage() {
      this.cursor = {
        after: this.sourceUsers.pageInfo.endCursor,
        before: null,
      };
    },
  },
};
</script>

<template>
  <gl-tabs v-model="selectedTabIndex" class="gl-mt-3">
    <gl-tab>
      <template #title>
        <span>{{ s__('UserMapping|Awaiting reassignment') }}</span>
        <gl-badge class="gl-tab-counter-badge">{{ unassignedCount || 0 }}</gl-badge>
      </template>

      <placeholders-table
        key="unassigned"
        :items="nodes"
        :page-info="pageInfo"
        :is-loading="isLoading"
        @confirm="onConfirm"
        @prev="onPrevPage"
        @next="onNextPage"
      />
    </gl-tab>

    <gl-tab>
      <template #title>
        <span>{{ s__('UserMapping|Reassigned') }}</span>
        <gl-badge class="gl-tab-counter-badge">{{ reassignedCount || 0 }}</gl-badge>
      </template>

      <placeholders-table
        key="reassigned"
        reassigned
        :items="nodes"
        :page-info="pageInfo"
        :is-loading="isLoading"
        @prev="onPrevPage"
        @next="onNextPage"
      />
    </gl-tab>
  </gl-tabs>
</template>
