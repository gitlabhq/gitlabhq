<script>
import { GlButton, GlIcon, GlAlert, GlTabs, GlTab, GlLink } from '@gitlab/ui';
import TabTitle from './tab_title.vue';
import MergeRequestsQuery from './merge_requests_query.vue';
import CollapsibleSection from './collapsible_section.vue';
import MergeRequest from './merge_request.vue';

export default {
  components: {
    GlButton,
    GlIcon,
    GlAlert,
    GlTabs,
    GlTab,
    GlLink,
    TabTitle,
    MergeRequestsQuery,
    CollapsibleSection,
    MergeRequest,
  },
  inject: ['mergeRequestsSearchDashboardPath', 'newListsEnabled'],
  props: {
    tabs: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      currentTab: this.$route.params.filter || '',
    };
  },
  methods: {
    clickTab({ key }) {
      this.currentTab = key;
      this.$router.push({ path: key || '/' });
    },
    queriesForTab(tab) {
      return tab.lists
        .flat()
        .filter((l) => !l.hideCount)
        .map((list) => ({ query: list.query, variables: list.variables }));
    },
  },
};
</script>

<template>
  <div>
    <gl-tabs no-key-nav>
      <gl-tab
        v-for="tab in tabs"
        :key="tab.title"
        :active="tab.key === currentTab"
        lazy
        @click="clickTab(tab)"
      >
        <template #title>
          <tab-title :title="tab.title" :queries="queriesForTab(tab)" :tab-key="tab.key" />
        </template>
        <div v-for="(lists, i) in tab.lists" :key="`lists_${i}`">
          <div
            v-if="i === 1 && newListsEnabled"
            class="gl-mt-8 gl-rounded-base gl-bg-gray-50 gl-px-4 gl-py-2 gl-font-bold gl-text-subtle"
            data-testid="merge-request-count-explanation"
          >
            {{ __('Items below are excluded from the active count') }}
          </div>
          <merge-requests-query
            v-for="list in lists"
            :key="`list_${list.id}`"
            :query="list.query"
            :variables="list.variables"
            :hide-count="list.hideCount"
            :class="{ '!gl-mt-3': i === 0 }"
          >
            <template #default="{ mergeRequests, count, hasNextPage, loadMore, loading, error }">
              <collapsible-section
                :count="count"
                :has-merge-requests="mergeRequests.length > 0"
                :title="list.title"
                :help-content="list.helpContent"
                :loading="loading"
              >
                <div>
                  <div class="gl-overflow-x-auto">
                    <table class="gl-w-full">
                      <colgroup>
                        <col v-if="!newListsEnabled" style="width: 60px" />
                        <col :style="newListsEnabled ? 'width: 210px;' : 'width: 70px;'" />
                        <col
                          :style="{ width: newListsEnabled ? '40%' : '47%', minWidth: '200px' }"
                        />
                        <col style="width: 120px" />
                        <col style="width: 120px" />
                        <col :style="newListsEnabled ? 'width: 220px;' : 'min-width: 200px;'" />
                      </colgroup>
                      <thead class="gl-border-b gl-bg-subtle">
                        <tr>
                          <th v-if="!newListsEnabled" class="gl-pb-3 gl-pl-5 gl-pr-3">
                            <gl-icon name="pipeline" />
                            <span class="gl-sr-only">{{ __('Pipeline status') }}</span>
                          </th>
                          <th
                            class="gl-px-3 gl-pb-3"
                            :class="{ 'gl-text-sm gl-text-subtle': newListsEnabled }"
                          >
                            <template v-if="newListsEnabled">
                              {{ __('Status') }}
                            </template>
                            <template v-else>
                              <gl-icon name="approval" />
                              <span class="gl-sr-only">{{ __('Approvals') }}</span>
                            </template>
                          </th>
                          <th class="gl-px-3 gl-pb-3 gl-text-sm gl-text-subtle">
                            {{ __('Title') }}
                          </th>
                          <th class="gl-px-3 gl-pb-3 gl-text-center gl-text-sm gl-text-subtle">
                            {{ __('Assignee') }}
                          </th>
                          <th class="gl-px-3 gl-pb-3 gl-text-center gl-text-sm gl-text-subtle">
                            {{ __('Reviewers') }}
                          </th>
                          <th
                            class="gl-pb-3 gl-pl-3 gl-pr-5 gl-text-right gl-text-sm gl-text-subtle"
                          >
                            <template v-if="newListsEnabled">
                              {{ __('Checks') }}
                            </template>
                            <template v-else>
                              {{ __('Activity') }}
                            </template>
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
                            :list-id="list.id"
                            data-testid="merge-request"
                          />
                        </template>
                        <tr v-else>
                          <td
                            :colspan="newListsEnabled ? 5 : 6"
                            :class="{ 'gl-py-6 gl-text-center': !error }"
                          >
                            <template v-if="loading">
                              {{ __('Loading...') }}
                            </template>
                            <template v-else-if="error">
                              <gl-alert variant="danger" :dismissible="false">
                                {{
                                  __(
                                    'There was an error fetching merge requests. Please try again.',
                                  )
                                }}
                              </gl-alert>
                            </template>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                </div>
                <template #pagination>
                  <div
                    v-if="hasNextPage"
                    class="crud-pagination-container gl-flex gl-justify-center"
                  >
                    <gl-button :loading="loading" data-testid="load-more" @click="loadMore">{{
                      __('Show more')
                    }}</gl-button>
                  </div>
                </template>
              </collapsible-section>
            </template>
          </merge-requests-query>
        </div>
      </gl-tab>
      <template #tabs-end>
        <li role="presentation" class="nav-item">
          <gl-link
            :href="mergeRequestsSearchDashboardPath"
            class="nav-link gl-tab-nav-item !gl-no-underline"
          >
            {{ __('Search') }}
          </gl-link>
        </li>
      </template>
    </gl-tabs>
    <div class="gl-mt-6 gl-text-center">
      <gl-link v-if="newListsEnabled" href="https://gitlab.com/gitlab-org/gitlab/-/issues/512314">
        {{ __('Leave feedback') }}
      </gl-link>
      <gl-link v-else href="https://gitlab.com/gitlab-org/gitlab/-/issues/497573">
        {{ __('Leave feedback') }}
      </gl-link>
    </div>
  </div>
</template>
