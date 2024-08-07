<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { GlBadge, GlTab, GlTabs, GlButton, GlModalDirective } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__, sprintf } from '~/locale';
import { getParameterByName } from '~/lib/utils/url_utility';
import {
  PLACEHOLDER_STATUS_FAILED,
  QUERY_PARAM_FAILED,
} from '~/import_entities/import_groups/constants';

import importSourceUsersQuery from '../graphql/queries/import_source_users.query.graphql';
import PlaceholdersTable from './placeholders_table.vue';
import CsvUploadModal from './csv_upload_modal.vue';

const UPLOAD_CSV_PLACEHOLDERS_MODAL_ID = 'upload-placeholders-csv-modal';

const DEFAULT_PAGE_SIZE = 20;

export default {
  name: 'PlaceholdersTabApp',
  components: {
    GlBadge,
    GlTab,
    GlTabs,
    GlButton,
    PlaceholdersTable,
    CsvUploadModal,
  },
  directives: {
    GlModal: GlModalDirective,
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
          statuses: this.queryStatuses,
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
    statusParamValue() {
      return getParameterByName('status');
    },
    queryStatuses() {
      if (getParameterByName('status') === QUERY_PARAM_FAILED) {
        return [PLACEHOLDER_STATUS_FAILED];
      }

      return [];
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
  uploadCsvModalId: UPLOAD_CSV_PLACEHOLDERS_MODAL_ID,
};
</script>

<template>
  <gl-tabs v-model="selectedTabIndex" nav-class="gl-grow gl-items-center gl-mt-3">
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

    <template #tabs-end>
      <gl-button
        v-gl-modal="$options.uploadCsvModalId"
        variant="link"
        icon="media"
        class="gl-ml-auto"
        data-testid="reassign-csv-button"
      >
        {{ s__('UserMapping|Reassign with CSV file') }}
      </gl-button>
      <csv-upload-modal :modal-id="$options.uploadCsvModalId" />
    </template>
  </gl-tabs>
</template>
