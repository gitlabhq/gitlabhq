<script>
import { GlLink, GlLoadingIcon, GlIcon } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import { sprintf, __, n__ } from '~/locale';
import RelatedIssuableItem from '~/issuable/components/related_issuable_item.vue';

export default {
  name: 'RelatedMergeRequests',
  components: {
    GlIcon,
    GlLink,
    GlLoadingIcon,
    RelatedIssuableItem,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    hasClosingMergeRequest: {
      type: Boolean,
      required: false,
      default: false,
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

      return sprintf(__('%{mrText}, this issue will be closed automatically.'), { mrText });
    },
  },
  mounted() {
    this.setInitialState({ apiEndpoint: this.endpoint });
    this.fetchMergeRequests();
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
                class="gl-mx-n2"
              />
            </li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>
