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
  inject: ['mergeRequestsSearchDashboardPath'],
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
        <merge-requests-query
          v-for="(list, i) in tab.lists"
          :key="`list_${i}`"
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
                      <col style="width: 60px" />
                      <col style="width: 70px" />
                      <col style="width: 47%; min-width: 200px" />
                      <col style="width: 120px" />
                      <col style="width: 120px" />
                      <col style="min-width: 200px" />
                    </colgroup>
                    <thead class="gl-border-b gl-bg-subtle">
                      <tr>
                        <th class="gl-pb-3 gl-pl-5 gl-pr-3" :aria-label="__('Pipeline status')">
                          <gl-icon name="pipeline" />
                          <span class="gl-sr-only">{{ __('Pipeline status') }}</span>
                        </th>
                        <th class="gl-px-3 gl-pb-3" :aria-label="__('Approvals')">
                          <gl-icon name="approval" />
                          <span class="gl-sr-only">{{ __('Approvals') }}</span>
                        </th>
                        <th class="gl-px-3 gl-pb-3 gl-text-sm gl-text-gray-700">
                          {{ __('Title') }}
                        </th>
                        <th class="gl-px-3 gl-pb-3 gl-text-center gl-text-sm gl-text-gray-700">
                          {{ __('Assignee') }}
                        </th>
                        <th class="gl-px-3 gl-pb-3 gl-text-center gl-text-sm gl-text-gray-700">
                          {{ __('Reviewers') }}
                        </th>
                        <th
                          class="gl-pb-3 gl-pl-3 gl-pr-5 gl-text-right gl-text-sm gl-text-gray-700"
                        >
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
                          data-testid="merge-request"
                        />
                      </template>
                      <tr v-else>
                        <td colspan="6" :class="{ 'gl-py-6 gl-text-center': !error }">
                          <template v-if="loading">
                            {{ __('Loading...') }}
                          </template>
                          <template v-else-if="error">
                            <gl-alert variant="danger" :dismissible="false">
                              {{
                                __('There was an error fetching merge requests. Please try again.')
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
                <div v-if="hasNextPage" class="gl-mt-4 gl-flex gl-justify-center">
                  <gl-button :loading="loading" data-testid="load-more" @click="loadMore">{{
                    __('Show more')
                  }}</gl-button>
                </div>
              </template>
            </collapsible-section>
          </template>
        </merge-requests-query>
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
      <gl-link href="https://gitlab.com/gitlab-org/gitlab/-/issues/497573">
        {{ __('Leave feedback') }}
      </gl-link>
    </div>
  </div>
</template>
