<script>
import { GlLink, GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { sprintf, __, n__ } from '~/locale';
import RelatedIssuableItem from '~/issuable/components/related_issuable_item.vue';
import { parseIssuableData } from '~/issues/show/utils/parse_data';

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
    <div class="card card-slim gl-mt-5 gl-mb-0 gl-bg-gray-10">
      <div class="card-header gl-px-5 gl-py-4 gl-bg-white">
        <div
          class="card-title gl-relative gl-display-flex gl-flex-wrap gl-align-items-center gl-line-height-20 gl-font-weight-bold gl-m-0"
        >
          <gl-link
            class="anchor gl-absolute gl-text-decoration-none"
            href="#related-merge-requests"
            aria-labelledby="related-merge-requests"
          />
          <h3 id="related-merge-requests" class="gl-font-base gl-m-0">
            {{ __('Related merge requests') }}
          </h3>
          <template v-if="totalCount">
            <gl-icon name="merge-request" class="gl-ml-3 gl-mr-2 gl-text-gray-500" />
            <span data-testid="count" class="gl-text-gray-500">{{ totalCount }}</span>
          </template>
          <p
            v-if="hasClosingMergeRequest && !isFetchingMergeRequests"
            class="gl-font-sm gl-font-weight-normal gl-flex-basis-full gl-mb-0 gl-text-gray-500"
          >
            {{ closingMergeRequestsText }}
          </p>
        </div>
      </div>
      <gl-loading-icon
        v-if="isFetchingMergeRequests"
        size="sm"
        label="Fetching related merge requests"
        class="gl-py-4"
      />
      <ul v-else class="content-list related-items-list gl-px-4! gl-py-3!">
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
</template>
