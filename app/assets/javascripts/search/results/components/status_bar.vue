<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { n__ } from '~/locale';
import RefSelector from '~/ref/components/ref_selector.vue';
import { REF_FIELD_NAME } from '~/search/results/constants';
import { getBaseURL, setUrlParams, visitUrl } from '~/lib/utils/url_utility';

export default {
  name: 'GlobalSearchStatusBar',
  components: {
    GlSprintf,
    GlLink,
    RefSelector,
  },
  props: {
    blobSearch: {
      type: Object,
      required: true,
    },
    hasResults: {
      type: Boolean,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    error: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapState(['query', 'groupInitialJson', 'projectInitialJson', 'repositoryRef']),
    currentPage() {
      return this.query.page ? parseInt(this.query.page, 10) : 1;
    },
    filesPerPage() {
      return this.blobSearch.perPage;
    },
    allFilesResults() {
      return this.blobSearch.fileCount;
    },
    showingFilesFrom() {
      return this.filesPerPage * (this.currentPage - 1) + 1;
    },
    showingFilesTo() {
      return Math.min(this.filesPerPage * this.currentPage, this.allFilesResults);
    },
    resultsTotal() {
      return this.blobSearch?.matchCount;
    },
    showBar() {
      return this.hasResults && !this.hasError && !this.isLoading;
    },
    getBaseURL() {
      return getBaseURL();
    },
    resultsSimple() {
      return n__(
        'GlobalSearch|Showing 1 code result for %{term}',
        'GlobalSearch|Showing %{resultsTotal} code results for %{term}',
        this?.resultsTotal ?? 0,
      );
    },
    statusGroup() {
      return n__(
        'GlobalSearch|Showing 1 code result for %{term} in group %{groupNameLink}',
        'GlobalSearch|Showing %{resultsTotal} code results for %{term} in group %{groupNameLink}',
        this?.resultsTotal ?? 0,
      );
    },
    statusProject() {
      return n__(
        'GlobalSearch|Showing 1 code result for %{term} in %{branchDropdown} of %{ProjectWithGroupPathLink}',
        'GlobalSearch|Showing %{resultsTotal} code results for %{term} in %{branchDropdown} of %{ProjectWithGroupPathLink}',
        this?.resultsTotal ?? 0,
      );
    },
    hasError() {
      return Boolean(this.error);
    },
  },
  methods: {
    handleInput(selected) {
      visitUrl(setUrlParams({ ...this.query, [REF_FIELD_NAME]: selected }));
    },
  },
};
</script>

<template>
  <div v-if="showBar" class="search-results-status gl-my-4">
    <gl-sprintf v-if="!query.project_id && !query.group_id" :message="resultsSimple">
      <template #resultsTotal>{{ resultsTotal }}</template>
      <template #term
        ><code>{{ query.search }}</code></template
      >
    </gl-sprintf>

    <gl-sprintf v-if="!query.project_id && query.group_id" :message="statusGroup">
      <template #resultsTotal>{{ resultsTotal }}</template>
      <template #term
        ><code>{{ query.search }}</code></template
      ><template #groupNameLink
        ><gl-link :href="`${getBaseURL}/${groupInitialJson.full_path}`">{{
          groupInitialJson.full_name
        }}</gl-link></template
      >
    </gl-sprintf>

    <gl-sprintf v-if="query.project_id" :message="statusProject">
      <template #resultsTotal>{{ resultsTotal }}</template>
      <template #term
        ><code>{{ query.search }}</code></template
      >
      <template #branchDropdown>
        <ref-selector
          :project-id="String(projectInitialJson.id)"
          :value="repositoryRef"
          class="gl-inline-block"
          @input="handleInput"
        />
      </template>
      <template #ProjectWithGroupPathLink
        ><gl-link :href="`${getBaseURL}/${projectInitialJson.full_path}`">{{
          projectInitialJson.name_with_namespace
        }}</gl-link></template
      >
    </gl-sprintf>
  </div>
</template>
