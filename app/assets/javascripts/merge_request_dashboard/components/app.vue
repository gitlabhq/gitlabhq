<script>
import { GlButton, GlAlert, GlTabs, GlTab, GlLink, GlBanner, GlSprintf } from '@gitlab/ui';
import mergeRequestIllustration from '@gitlab/svgs/dist/illustrations/merge-requests-sm.svg';
import Visibility from 'visibilityjs';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import eventHub from '../event_hub';
import userMergeRequestUpdatedSubscription from '../queries/user_merge_request_updated.subscription.graphql';
import TabTitle from './tab_title.vue';
import MergeRequestsQuery from './merge_requests_query.vue';
import CollapsibleSection from './collapsible_section.vue';
import MergeRequest from './merge_request.vue';
import DraftsCount from './drafts_count.vue';

export default {
  name: 'MergeRequestDashboardRoot',
  apollo: {
    $subscribe: {
      // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
      currentUserUpdated: {
        query: userMergeRequestUpdatedSubscription,
        variables() {
          return {
            userId: this.currentUserId,
          };
        },
        result({ data: { userMergeRequestUpdated: mergeRequest } }) {
          if (!mergeRequest) return;

          const isAssignee = mergeRequest.assignees.nodes.some((u) => u.id === this.currentUserId);
          const isAuthor = mergeRequest.author.id === this.currentUserId;
          const isReviewer = mergeRequest.reviewers.nodes.some((u) => u.id === this.currentUserId);

          if (isAssignee) eventHub.$emit('refetch.mergeRequests', 'assignedMergeRequests');
          if (isAssignee || isAuthor)
            eventHub.$emit('refetch.mergeRequests', 'authorOrAssigneeMergeRequests');
          if (isReviewer) eventHub.$emit('refetch.mergeRequests', 'reviewRequestedMergeRequests');
        },
      },
    },
  },
  components: {
    GlButton,
    GlAlert,
    GlTabs,
    GlTab,
    GlLink,
    GlBanner,
    GlSprintf,
    UserCalloutDismisser,
    TabTitle,
    MergeRequestsQuery,
    CollapsibleSection,
    MergeRequest,
    DraftsCount,
  },
  inject: ['mergeRequestsSearchDashboardPath'],
  props: {
    tabs: {
      type: Array,
      required: true,
    },
  },
  data() {
    const currentTab = this.$route.params.filter || '';

    return {
      currentTab,
      isVisible: !Visibility.hidden(),
      visitedTabs: new Set([currentTab]),
    };
  },
  computed: {
    currentUserId() {
      return convertToGraphQLId(TYPENAME_USER, gon.current_user_id);
    },
  },
  mounted() {
    Visibility.change(() => this.onVisibilityChange());
  },
  methods: {
    onVisibilityChange() {
      this.isVisible = !Visibility.hidden();
    },
    clickTab({ key }) {
      if (this.currentTab === key) return;

      this.currentTab = key;

      // For tabs that we have already visited we cache that its been visited
      // and with this value we then stop the lazy rendering of the tabs
      // which causes GitLab UI tabs to not destroy and then re-create
      // the components inside.
      this.visitedTabs.add(key);

      this.$router.push({ path: key || '/' });
    },
    queriesForTab(tab) {
      return tab.lists
        .flat()
        .filter((l) => !l.hideCount)
        .map((list) => ({ query: list.query, variables: list.variables }));
    },
    tabAttributes(tab) {
      return { href: this.$router.resolve({ path: tab.key }).href };
    },
  },
  mergeRequestIllustration,
  docsPath: helpPagePath('/user/project/merge_requests/homepage.html'),
};
</script>

<template>
  <div>
    <user-callout-dismisser feature-name="new_merge_request_dashboard_welcome">
      <template #default="{ shouldShowCallout, dismiss }">
        <gl-banner
          v-if="shouldShowCallout"
          :title="__('New, streamlined merge request homepage!')"
          variant="introduction"
          :button-text="__('See how it works')"
          :button-link="$options.docsPath"
          :svg-path="$options.mergeRequestIllustration"
          @close="dismiss"
        >
          <p>
            {{
              __(
                "Welcome to the new merge request homepage! This page gives you a centralized view of all the merge requests you're working on. Know at a glance what merge requests need your attention first so you can spend less time checking in, and more time reviewing and responding to feedback.",
              )
            }}
          </p>
        </gl-banner>
      </template>
    </user-callout-dismisser>
    <gl-tabs no-key-nav>
      <gl-tab
        v-for="tab in tabs"
        :key="tab.title"
        :active="tab.key === currentTab"
        :lazy="!visitedTabs.has(tab.key)"
        :title-link-attributes="tabAttributes(tab)"
        data-testid="merge-request-dashboard-tab"
        @click="clickTab(tab)"
      >
        <template #title>
          <tab-title :title="tab.title" :queries="queriesForTab(tab)" />
        </template>
        <div v-for="(lists, i) in tab.lists" :key="`lists_${i}`">
          <div
            v-if="i === 1"
            class="gl-mb-5 gl-mt-8 gl-rounded-base gl-bg-strong gl-px-4 gl-py-2 gl-font-bold gl-text-subtle"
            data-testid="merge-request-count-explanation"
          >
            {{ __('Items below are excluded from the active count') }}
          </div>
          <merge-requests-query
            v-for="(list, listIndex) in lists"
            :key="`list_${list.id}`"
            :query="list.query"
            :variables="list.variables"
            :hide-count="list.hideCount"
            :is-visible="isVisible"
          >
            <template
              #default="{
                mergeRequests,
                newMergeRequestIds,
                count,
                hasNextPage,
                loadMore,
                loading,
                error,
                resetNewMergeRequestIds,
                draftsCount,
              }"
            >
              <collapsible-section
                :id="list.id"
                :hide-count="list.hideCount"
                :count="count"
                :has-merge-requests="mergeRequests.length > 0"
                :title="list.title"
                :help-content="list.helpContent"
                :loading="loading"
                :error="error"
                :new-merge-request-ids="newMergeRequestIds"
                :merge-requests="mergeRequests"
                :active-list="i === 0"
                :class="{
                  '!gl-mt-0': listIndex === 0,
                  '!gl-mt-3': listIndex > 0,
                }"
                data-testid="merge-request-dashboard-list"
                @clear-new="resetNewMergeRequestIds"
              >
                <div
                  class="gl-grid gl-grid-cols-[minmax(200px,1fr),minmax(250px,40%),repeat(2,minmax(110px,1fr)),minmax(200px,1fr)] gl-gap-x-4 gl-overflow-x-auto"
                  role="table"
                >
                  <div
                    class="gl-border-b gl-col-span-full gl-grid gl-grid-cols-subgrid gl-px-5 gl-pb-3"
                    role="row"
                  >
                    <div class="gl-text-sm gl-font-[700] gl-text-subtle" role="columnheader">
                      {{ __('Status') }}
                    </div>
                    <div class="gl-text-sm gl-font-[700] gl-text-subtle" role="columnheader">
                      {{ __('Title') }}
                    </div>
                    <div
                      class="gl-text-center gl-text-sm gl-font-[700] gl-text-subtle"
                      role="columnheader"
                    >
                      {{ __('Assignee') }}
                    </div>
                    <div
                      class="gl-text-center gl-text-sm gl-font-[700] gl-text-subtle"
                      role="columnheader"
                    >
                      {{ __('Reviewers') }}
                    </div>
                    <div
                      class="gl-text-right gl-text-sm gl-font-[700] gl-text-subtle"
                      role="columnheader"
                    >
                      {{ __('Checks') }}
                    </div>
                  </div>
                  <template v-if="mergeRequests.length">
                    <merge-request
                      v-for="(mergeRequest, index) in mergeRequests"
                      :key="mergeRequest.id"
                      :merge-request="mergeRequest"
                      :new-merge-request-ids="newMergeRequestIds"
                      :list-id="list.id"
                      data-testid="merge-request"
                      class="gl-col-span-full gl-grid gl-grid-cols-subgrid gl-px-5 gl-py-4"
                      :class="{ 'gl-border-b': index < mergeRequests.length - 1 }"
                    />
                  </template>
                  <div
                    v-else
                    class="gl-col-span-full"
                    :class="{ 'gl-py-6 gl-text-center': !error }"
                    role="row"
                  >
                    <template v-if="loading">
                      {{ __('Loading…') }}
                    </template>
                    <gl-alert v-else-if="error" variant="danger" :dismissible="false">
                      {{ __('There was an error fetching merge requests. Please try again.') }}
                    </gl-alert>
                  </div>
                </div>
                <template #drafts>
                  <drafts-count
                    v-if="draftsCount !== null && !loading"
                    :count="draftsCount"
                    class="gl-border-t gl-px-5 gl-py-3"
                  />
                </template>
                <template #pagination>
                  <div v-if="hasNextPage" class="crud-pagination-container">
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
            role="tab"
            :href="mergeRequestsSearchDashboardPath"
            class="nav-link gl-tab-nav-item !gl-no-underline"
          >
            {{ __('Search') }}
          </gl-link>
        </li>
      </template>
    </gl-tabs>
    <div class="gl-mt-6 gl-flex gl-justify-center gl-gap-3">
      <gl-sprintf
        :message="
          __('%{feedbackStart}Leave feedback%{feedbackEnd} | %{docStart}Documentation%{docEnd}')
        "
      >
        <template #feedback="{ content }">
          <gl-link href="https://gitlab.com/gitlab-org/gitlab/-/issues/542823">
            {{ content }}
          </gl-link>
        </template>
        <template #doc="{ content }">
          <gl-link :href="$options.docsPath">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </div>
  </div>
</template>
