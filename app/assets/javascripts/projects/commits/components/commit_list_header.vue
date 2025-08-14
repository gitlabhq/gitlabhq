<script>
import { visitUrl, joinPaths } from '~/lib/utils/url_utility';
import { generateRefDestinationPath } from '~/repository/utils/ref_switcher_utils';
import RefSelector from '~/ref/components/ref_selector.vue';
import CommitFilteredSearch from './commit_filtered_search.vue';
import CommitListBreadcrumb from './commit_list_breadcrumb.vue';

export default {
  name: 'CommitHeader',
  components: {
    RefSelector,
    CommitFilteredSearch,
    CommitListBreadcrumb,
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
    <div class="gl-flex gl-items-center gl-gap-5">
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
      <commit-list-breadcrumb class="gl-grow" />
    </div>

    <div class="gl-my-5">
      <h1 class="gl-m-0 gl-text-size-h1">{{ __('Commits') }}</h1>
    </div>

    <commit-filtered-search @filter="$emit('filter', $event)" />
  </div>
</template>
