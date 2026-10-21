<script>
import {
  GlModalDirective,
  GlTable,
  GlFriendlyWrap,
  GlLink,
  GlButton,
  GlLoadingIcon,
  GlPagination,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters, mapActions } from 'vuex';
import SimpleCopyButton from '~/vue_shared/components/simple_copy_button.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { __ } from '~/locale';
import { WRAP_SYMBOLS } from '../stores/test_reports/constants';
import TestCaseDetails from './test_case_details.vue';

export default {
  name: 'TestSearchResults',
  components: {
    CiIcon,
    GlFriendlyWrap,
    GlLink,
    GlButton,
    GlLoadingIcon,
    GlPagination,
    GlTable,
    SimpleCopyButton,
    TestCaseDetails,
  },
  directives: {
    GlModalDirective,
  },
  computed: {
    ...mapState('testReports', ['pageInfo', 'isLoadingAllSuites']),
    ...mapGetters('testReports', ['getSearchResults', 'getSearchResultsCount']),
    hasResults() {
      return this.getSearchResultsCount > 0;
    },
  },
  methods: {
    ...mapActions('testReports', ['setPage']),
  },
  wrapSymbols: WRAP_SYMBOLS,
  fields: [
    { key: 'suiteName', label: __('Job') },
    { key: 'classname', label: __('Suite') },
    { key: 'name', label: __('Name') },
    { key: 'file', label: __('Filename') },
    { key: 'status', label: __('Status'), tdClass: 'gl-text-center' },
    { key: 'formattedTime', label: __('Duration') },
    { key: 'details', label: __('Details') },
  ],
};
</script>

<template>
  <div class="test-reports-table gl-mb-3">
    <gl-loading-icon v-if="isLoadingAllSuites" size="lg" class="gl-mt-5" />

    <template v-else-if="!isLoadingAllSuites">
      <p v-if="!hasResults" class="gl-mt-3" data-testid="no-search-results">
        {{ s__('TestReports|No test cases match your search.') }}
      </p>

      <template v-else>
        <gl-table
          :items="getSearchResults"
          :fields="$options.fields"
          data-testid="test-search-results-table"
        >
          <template #cell(suiteName)="{ item }">
            <gl-friendly-wrap :symbols="$options.wrapSymbols" :text="item.suiteName" />
          </template>

          <template #cell(classname)="{ item }">
            <gl-friendly-wrap :symbols="$options.wrapSymbols" :text="item.classname" />
          </template>

          <template #cell(name)="{ item }">
            <gl-friendly-wrap :symbols="$options.wrapSymbols" :text="item.name" />
          </template>

          <template #cell(file)="{ item }">
            <gl-link
              v-if="item.file"
              :href="item.filePath"
              target="_blank"
              rel="noopener noreferrer"
            >
              <gl-friendly-wrap :symbols="$options.wrapSymbols" :text="item.file" />
            </gl-link>
            <simple-copy-button size="small" category="tertiary" :text="item.file" />
          </template>

          <template #cell(status)="{ item }">
            <ci-icon v-if="item" :status="item" :show-tooltip="false" :use-link="false" />
          </template>

          <template #cell(details)="{ item, index }">
            <gl-button v-gl-modal-directive="`test-search-result-details-${index}`">{{
              __('View details')
            }}</gl-button>
            <test-case-details
              :modal-id="`test-search-result-details-${index}`"
              :test-case="item"
            />
          </template>
        </gl-table>

        <gl-pagination
          v-model="pageInfo.page"
          class="gl-flex gl-justify-center"
          :per-page="pageInfo.perPage"
          :total-items="getSearchResultsCount"
          @input="setPage"
        />
      </template>
    </template>
  </div>
</template>
