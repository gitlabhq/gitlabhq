<script>
import { mapActions } from 'vuex';
import { GlBadge, GlSprintf } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  name: 'TestIssueBody',
  components: {
    GlBadge,
    GlSprintf,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    issue: {
      type: Object,
      required: true,
    },
    // failed || success
    status: {
      type: String,
      required: true,
    },
    isNew: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    showRecentFailures() {
      return (
        this.glFeatures.testFailureHistory &&
        this.issue.recent_failures?.count &&
        this.issue.recent_failures?.base_branch
      );
    },
  },
  methods: {
    ...mapActions(['openModal']),
  },
};
</script>
<template>
  <div class="report-block-list-issue-description gl-mt-2 gl-mb-2">
    <div class="report-block-list-issue-description-text" data-testid="test-issue-body-description">
      <button
        type="button"
        class="btn-link btn-blank text-left break-link vulnerability-name-button"
        @click="openModal({ issue })"
      >
        <gl-badge v-if="isNew" variant="danger" class="gl-mr-2">{{ s__('New') }}</gl-badge>
        <gl-badge v-if="showRecentFailures" variant="warning" class="gl-mr-2">
          <gl-sprintf
            :message="
              n__(
                'Reports|Failed %{count} time in %{base_branch} in the last 14 days',
                'Reports|Failed %{count} times in %{base_branch} in the last 14 days',
                issue.recent_failures.count,
              )
            "
          >
            <template #count>{{ issue.recent_failures.count }}</template>
            <template #base_branch>{{ issue.recent_failures.base_branch }}</template>
          </gl-sprintf>
        </gl-badge>
        {{ issue.name }}
      </button>
    </div>
  </div>
</template>
