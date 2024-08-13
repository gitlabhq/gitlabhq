<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { GlBadge, GlTab, GlTabs, GlButton, GlModalDirective } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__, sprintf } from '~/locale';
import { getParameterByName } from '~/lib/utils/url_utility';
import {
  PLACEHOLDER_STATUS_FAILED,
  QUERY_PARAM_FAILED,
  PLACEHOLDER_USER_STATUS,
} from '~/import_entities/import_groups/constants';

import PlaceholdersTable from './placeholders_table.vue';
import CsvUploadModal from './csv_upload_modal.vue';

const UPLOAD_CSV_PLACEHOLDERS_MODAL_ID = 'upload-placeholders-csv-modal';

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
  mixins: [glFeatureFlagsMixin()],
  data() {
    return {
      selectedTabIndex: 0,
      unassignedCount: null,
      reassignedCount: null,
    };
  },
  computed: {
    ...mapState('placeholder', ['pagination']),
    unassignedUserStatuses() {
      if (getParameterByName('status') === QUERY_PARAM_FAILED) {
        return [PLACEHOLDER_STATUS_FAILED];
      }

      return PLACEHOLDER_USER_STATUS.UNASSIGNED;
    },
    reassignedUserStatuses() {
      return PLACEHOLDER_USER_STATUS.REASSIGNED;
    },
    isCsvReassignmentEnabled() {
      return this.glFeatures.importerUserMappingReassignmentCsv;
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
        data-testid="placeholders-table-unassigned"
        :query-statuses="unassignedUserStatuses"
        @confirm="onConfirm"
      />
    </gl-tab>

    <gl-tab>
      <template #title>
        <span>{{ s__('UserMapping|Reassigned') }}</span>
        <gl-badge class="gl-tab-counter-badge">{{ reassignedCount || 0 }}</gl-badge>
      </template>

      <placeholders-table
        key="reassigned"
        data-testid="placeholders-table-reassigned"
        :query-statuses="reassignedUserStatuses"
        reassigned
      />
    </gl-tab>

    <template #tabs-end>
      <div v-if="isCsvReassignmentEnabled" class="gl-ml-auto">
        <gl-button
          v-gl-modal="$options.uploadCsvModalId"
          variant="link"
          icon="media"
          data-testid="reassign-csv-button"
        >
          {{ s__('UserMapping|Reassign with CSV file') }}
        </gl-button>
        <csv-upload-modal :modal-id="$options.uploadCsvModalId" />
      </div>
    </template>
  </gl-tabs>
</template>
