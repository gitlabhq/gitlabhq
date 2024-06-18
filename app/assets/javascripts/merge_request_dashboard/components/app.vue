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
      <template #default="{ mergeRequests, count, hasNextPage, loadMore, loading }">
        <collapsible-section :count="count" :loading="loading" :title="list.title">
          <div v-if="!mergeRequests.length && loading" class="gl-bg-white gl-p-5 gl-rounded-base">
            <div class="gl-display-flex gl-mb-2">
              <div class="gl-animate-skeleton-loader gl-h-4 gl-rounded-base gl-w-20 gl-mt-1"></div>
              <div class="gl-ml-auto gl-display-flex">
                <div class="gl-animate-skeleton-loader gl-h-6 gl-rounded-full gl-w-6"></div>
                <div class="gl-animate-skeleton-loader gl-h-6 gl-ml-4 gl-rounded-full gl-w-6"></div>
              </div>
            </div>
            <div class="gl-display-flex">
              <div class="gl-animate-skeleton-loader gl-h-3 gl-rounded-base gl-w-30"></div>
              <div
                class="gl-animate-skeleton-loader gl-h-3 gl-rounded-base gl-w-20 gl-ml-auto"
              ></div>
            </div>
          </div>
          <merge-request
            v-for="(mergeRequest, index) in mergeRequests"
            :key="mergeRequest.id"
            :merge-request="mergeRequest"
            :class="{ 'gl-mb-3': index !== mergeRequests.length - 1 }"
          />
          <div v-if="hasNextPage" class="gl-display-flex gl-justify-content-center gl-mt-4">
            <gl-button :loading="loading" data-testid="load-more" @click="loadMore">{{
              __('Show more')
            }}</gl-button>
          </div>
        </collapsible-section>
      </template>
    </merge-requests-query>
  </div>
</template>
