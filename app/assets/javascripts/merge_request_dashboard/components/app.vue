<script>
import { GlButton } from '@gitlab/ui';
import ToggleLabels from '~/vue_shared/components/toggle_labels.vue';
import MergeRequestsQuery from './merge_requests_query.vue';
import CollapsibleSection from './collapsible_section.vue';
import MergeRequest from './merge_request.vue';

export default {
  components: {
    GlButton,
    ToggleLabels,
    MergeRequestsQuery,
    CollapsibleSection,
    MergeRequest,
  },
  props: {
    lists: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <div class="page-title-holder gl-flex">
      <h1 class="page-title gl-font-size-h-display">{{ __('Merge Requests') }}</h1>
      <div class="gl-ml-auto gl-align-self-center">
        <toggle-labels storage-key="gl-show-merge-request-labels" />
      </div>
    </div>
    <merge-requests-query
      v-for="(list, i) in lists"
      :key="`list_${i}`"
      :query="list.query"
      :variables="list.variables"
      :class="{ 'gl-mb-4': i !== lists.length - 1 }"
    >
      <template #default="{ mergeRequests, count, hasNextPage, loadMore, loadingMore }">
        <collapsible-section :count="count" :title="list.title">
          <merge-request
            v-for="(mergeRequest, index) in mergeRequests"
            :key="mergeRequest.id"
            :merge-request="mergeRequest"
            :class="{ 'gl-mb-3': index !== mergeRequests.length - 1 }"
          />
          <div v-if="hasNextPage" class="gl-display-flex gl-justify-content-center gl-mt-4">
            <gl-button :loading="loadingMore" data-testid="load-more" @click="loadMore">{{
              __('Show more')
            }}</gl-button>
          </div>
        </collapsible-section>
      </template>
    </merge-requests-query>
  </div>
</template>
