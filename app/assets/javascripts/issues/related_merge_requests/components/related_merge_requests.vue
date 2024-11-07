<script>
import produce from 'immer';
import { createAlert } from '~/alert';
import { sprintf, __, n__ } from '~/locale';
import RelatedIssuableItem from '~/issuable/components/related_issuable_item.vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
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
    CrudComponent,
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
  <crud-component
    v-if="isFetchingMergeRequests || (!isFetchingMergeRequests && totalCount)"
    anchor-id="related-merge-requests"
    :is-loading="isFetchingMergeRequests"
    :title="__('Related merge requests')"
    icon="merge-request"
    :count="totalCount"
    is-collapsible
  >
    <template v-if="hasClosingMergeRequest && !isFetchingMergeRequests" #description>
      {{ closingMergeRequestsText }}
    </template>
    <ul class="content-list related-items-list !-gl-mx-3 !gl-my-3">
      <li v-for="mr in mergeRequests" :key="mr.id" class="!gl-border-b-0 !gl-py-0">
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
        />
      </li>
    </ul>
  </crud-component>
</template>
