<script>
import { visitUrl, joinPaths } from '~/lib/utils/url_utility';
import { generateRefDestinationPath } from '~/repository/utils/ref_switcher_utils';
import RefSelector from '~/ref/components/ref_selector.vue';
import CommitFilteredSearch from './commit_filtered_search.vue';

export default {
  name: 'CommitHeader',
  components: {
    RefSelector,
    CommitFilteredSearch,
  },
  inject: ['projectRootPath', 'projectId', 'escapedRef', 'refType', 'rootRef'],
  computed: {
    refSelectorQueryParams() {
      return {
        sort: 'updated_desc',
      };
    },
    refSelectorValue() {
      return this.refType ? joinPaths('refs', this.refType, this.escapedRef) : this.escapedRef;
    },
  },
  methods: {
    onRefChange(selectedRef) {
      visitUrl(generateRefDestinationPath(this.projectRootPath, this.escapedRef, selectedRef));
    },
  },
};
</script>

<template>
  <div>
    <ref-selector
      class="gl-max-w-26"
      data-testid="commits-ref-selector"
      :project-id="projectId"
      :value="refSelectorValue"
      :default-branch="rootRef"
      use-symbolic-ref-names
      :query-params="refSelectorQueryParams"
      @input="onRefChange"
    />
    <h1 class="gl-text-size-h1">{{ __('Commits') }}</h1>
    <commit-filtered-search class="gl-mt-5" @filter="$emit('filter', $event)" />
  </div>
</template>
