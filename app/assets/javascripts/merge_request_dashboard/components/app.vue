<script>
import { GlButton, GlIcon, GlAlert } from '@gitlab/ui';
import MergeRequestsQuery from './merge_requests_query.vue';
import CollapsibleSection from './collapsible_section.vue';
import MergeRequest from './merge_request.vue';

export default {
  components: {
    GlButton,
    GlIcon,
    GlAlert,
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
    </div>
    <merge-requests-query
      v-for="(list, i) in lists"
      :key="`list_${i}`"
      :query="list.query"
      :variables="list.variables"
      :class="{ 'gl-mb-4': i !== lists.length - 1 }"
    >
      <template #default="{ mergeRequests, count, hasNextPage, loadMore, loading, error }">
        <collapsible-section :count="count" :loading="loading || error" :title="list.title">
          <div>
            <div class="gl-overflow-x-scroll">
              <table class="gl-w-full">
                <colgroup>
                  <col style="width: 60px" />
                  <col style="width: 70px" />
                  <col style="width: 47%; min-width: 200px" />
                  <col style="width: 120px" />
                  <col style="width: 120px" />
                  <col style="min-width: 200px" />
                </colgroup>
                <thead class="gl-bg-gray-10 gl-border-b">
                  <tr>
                    <th class="gl-pl-5 gl-pr-3 gl-pb-3" :aria-label="__('Pipeline status')">
                      <gl-icon name="pipeline" />
                    </th>
                    <th class="gl-pb-3 gl-px-3" :aria-label="__('Approvals')">
                      <gl-icon name="approval" />
                    </th>
                    <th class="gl-pb-3 gl-px-3 gl-text-sm gl-text-gray-700">{{ __('Title') }}</th>
                    <th class="gl-pb-3 gl-px-3 gl-text-sm gl-text-gray-700 gl-text-center">
                      {{ __('Assignee') }}
                    </th>
                    <th class="gl-pb-3 gl-px-3 gl-text-sm gl-text-gray-700 gl-text-center">
                      {{ __('Reviewers') }}
                    </th>
                    <th class="gl-pr-5 gl-pl-3 gl-pb-3 gl-text-sm gl-text-gray-700 gl-text-right">
                      {{ __('Activity') }}
                    </th>
                  </tr>
                </thead>
                <tbody>
                  <template v-if="mergeRequests.length">
                    <merge-request
                      v-for="(mergeRequest, index) in mergeRequests"
                      :key="mergeRequest.id"
                      :merge-request="mergeRequest"
                      :is-last="index === mergeRequests.length - 1"
                    />
                  </template>
                  <tr v-else>
                    <td colspan="6" :class="{ 'gl-py-6 gl-text-center': !error }">
                      <template v-if="loading">
                        {{ __('Loading...') }}
                      </template>
                      <template v-else-if="error">
                        <gl-alert variant="danger" :dismissible="false">
                          {{ __('There was an error fetching merge requests. Please try again.') }}
                        </gl-alert>
                      </template>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
          <template #pagination>
            <div v-if="hasNextPage" class="gl-flex gl-justify-center gl-mt-4">
              <gl-button :loading="loading" data-testid="load-more" @click="loadMore">{{
                __('Show more')
              }}</gl-button>
            </div>
          </template>
        </collapsible-section>
      </template>
    </merge-requests-query>
  </div>
</template>
