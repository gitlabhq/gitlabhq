<script>
import { mapState, mapActions } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import { sprintf, n__, s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import RelatedIssuableItem from '~/vue_shared/components/issue/related_issuable_item.vue';
import { parseIssuableData } from '../../issue_show/utils/parse_data';

export default {
  name: 'RelatedMergeRequests',
  components: {
    Icon,
    GlLoadingIcon,
    RelatedIssuableItem,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    projectNamespace: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(['isFetchingMergeRequests', 'mergeRequests', 'totalCount']),
    closingMergeRequestsText() {
      if (!this.hasClosingMergeRequest) {
        return '';
      }

      const mrText = n__(
        'When this merge request is accepted',
        'When these merge requests are accepted',
        this.totalCount,
      );

      return sprintf(s__('%{mrText}, this issue will be closed automatically.'), { mrText });
    },
  },
  mounted() {
    this.setInitialState({ apiEndpoint: this.endpoint });
    this.fetchMergeRequests();
  },
  created() {
    this.hasClosingMergeRequest = parseIssuableData().hasClosingMergeRequest;
  },
  methods: {
    ...mapActions(['setInitialState', 'fetchMergeRequests']),
    getAssignees(mr) {
      if (mr.assignees) {
        return mr.assignees;
      }

      return mr.assignee ? [mr.assignee] : [];
    },
  },
};
</script>

<template>
  <div v-if="isFetchingMergeRequests || (!isFetchingMergeRequests && totalCount)">
    <div id="merge-requests" class="card card-slim mt-3">
      <div class="card-header">
        <div class="card-title mt-0 mb-0 h5 merge-requests-title">
          <span class="mr-1">
            {{ __('Related merge requests') }}
          </span>
          <div v-if="totalCount" class="d-inline-flex lh-100 align-middle">
            <div class="mr-count-badge border-width-1px border-style-solid border-color-default">
              <div class="mr-count-badge-count">
                <svg class="s16 mr-1 text-secondary">
                  <icon name="merge-request" class="mr-1 text-secondary" />
                </svg>
                <span class="js-items-count">{{ totalCount }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div>
        <div v-if="isFetchingMergeRequests" class="qa-related-merge-requests-loading-icon">
          <gl-loading-icon label="Fetching related merge requests" class="py-2" />
        </div>
        <ul v-else class="content-list related-items-list">
          <li v-for="mr in mergeRequests" :key="mr.id" class="list-item pt-0 pb-0">
            <related-issuable-item
              :id-key="mr.id"
              :display-reference="mr.reference"
              :title="mr.title"
              :milestone="mr.milestone"
              :assignees="getAssignees(mr)"
              :created-at="mr.created_at"
              :closed-at="mr.closed_at"
              :merged-at="mr.merged_at"
              :path="mr.web_url"
              :state="mr.state"
              :is-merge-request="true"
              :pipeline-status="mr.head_pipeline && mr.head_pipeline.detailed_status"
              path-id-separator="!"
            />
          </li>
        </ul>
      </div>
    </div>
    <div
      v-if="hasClosingMergeRequest && !isFetchingMergeRequests"
      class="issue-closed-by-widget second-block"
    >
      {{ closingMergeRequestsText }}
    </div>
  </div>
</template>
