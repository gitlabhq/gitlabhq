<script>
import produce from 'immer';
import { GlLink, GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { sprintf, __, n__ } from '~/locale';
import RelatedIssuableItem from '~/issuable/components/related_issuable_item.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import relatedMergeRequestsQuery from '../queries/related_merge_requests.query.graphql';

export default {
  name: 'RelatedMergeRequests',
  apollo: {
    mergeRequests: {
      query: relatedMergeRequestsQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          iid: this.iid,
        };
      },
      update: (d) => d?.project?.issue?.relatedMergeRequests?.nodes,
      result({ data }) {
        const pageInfo = data?.project?.issue?.relatedMergeRequests?.pageInfo;

        this.totalCount = data?.project?.issue?.relatedMergeRequests?.count;

        if (pageInfo?.hasNextPage) {
          this.$apollo.queries.mergeRequests.fetchMore({
            variables: {
              projectPath: this.projectPath,
              iid: this.iid,
              after: pageInfo.endCursor,
            },
            updateQuery: (previousResult, { fetchMoreResult }) => {
              const newMergeRequests = fetchMoreResult.project.issue.relatedMergeRequests.nodes;
              const prevMergeRequests = previousResult.project.issue.relatedMergeRequests.nodes;

              return produce(fetchMoreResult, (draftData) => {
                draftData.project.issue.relatedMergeRequests.nodes =
                  prevMergeRequests.concat(newMergeRequests);
              });
            },
          });
        }
      },
      error() {
        createAlert({
          message: __('Something went wrong while fetching related merge requests.'),
        });
      },
    },
  },
  components: {
    GlIcon,
    GlLink,
    GlLoadingIcon,
    RelatedIssuableItem,
  },
  props: {
    hasClosingMergeRequest: {
      type: Boolean,
      required: false,
      default: false,
    },
    projectPath: {
      type: String,
      required: true,
    },
    iid: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      mergeRequests: null,
      totalCount: null,
    };
  },
  computed: {
    isFetchingMergeRequests() {
      return this.$apollo.queries.mergeRequests.loading;
    },
    closingMergeRequestsText() {
      if (!this.hasClosingMergeRequest) {
        return '';
      }

      const mrText = n__(
        'When this merge request is accepted',
        'When these merge requests are accepted',
        this.totalCount,
      );

      return sprintf(__('%{mrText}, this issue will be closed automatically.'), { mrText });
    },
  },
  methods: {
    idKey(mergeRequest) {
      return getIdFromGraphQLId(mergeRequest.id);
    },
    displayReference(mergeRequest) {
      const { fullPath } = mergeRequest.project;

      return `${this.projectPath !== fullPath ? fullPath : ''}${mergeRequest.reference}`;
    },
  },
};
</script>

<template>
  <div v-if="isFetchingMergeRequests || (!isFetchingMergeRequests && totalCount)">
    <div class="gl-new-card">
      <div class="gl-new-card-header gl-flex-direction-column">
        <div class="gl-new-card-title-wrapper">
          <gl-link
            class="anchor gl-absolute gl-text-decoration-none"
            href="#related-merge-requests"
            aria-labelledby="related-merge-requests"
          />
          <h3 id="related-merge-requests" class="gl-new-card-title">
            {{ __('Related merge requests') }}
          </h3>
          <div class="gl-new-card-count">
            <template v-if="totalCount">
              <gl-icon name="merge-request" class="gl-mr-2" />
              <span data-testid="count">{{ totalCount }}</span>
            </template>
          </div>
        </div>
        <p
          v-if="hasClosingMergeRequest && !isFetchingMergeRequests"
          class="gl-new-card-description"
        >
          {{ closingMergeRequestsText }}
        </p>
      </div>
      <div class="gl-new-card-body">
        <div class="gl-new-card-content">
          <gl-loading-icon
            v-if="isFetchingMergeRequests"
            size="sm"
            label="Fetching related merge requests"
            class="gl-py-2"
          />
          <ul class="content-list related-items-list">
            <li
              v-for="mr in mergeRequests"
              :key="mr.id"
              class="list-item gl-m-0! gl-p-0! gl-border-b-0!"
            >
              <related-issuable-item
                :id-key="idKey(mr)"
                :display-reference="displayReference(mr)"
                :title="mr.title"
                :milestone="mr.milestone"
                :assignees="mr.assignees.nodes"
                :created-at="mr.createdAt"
                :merged-at="mr.mergedAt"
                :path="mr.webUrl"
                :state="mr.state"
                :pipeline-status="mr.headPipeline && mr.headPipeline.detailedStatus"
                path-id-separator="!"
                is-merge-request
                class="-gl-mx-2"
              />
            </li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>
