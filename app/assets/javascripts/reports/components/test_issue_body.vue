<script>
import { mapActions } from 'vuex';
import { GlBadge } from '@gitlab/ui';
import { n__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  name: 'TestIssueBody',
  components: {
    GlBadge,
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
      return this.glFeatures.testFailureHistory && this.issue.recent_failures;
    },
  },
  methods: {
    ...mapActions(['openModal']),
    recentFailuresText(count) {
      return n__(
        'Failed %d time in the last 14 days',
        'Failed %d times in the last 14 days',
        count,
      );
    },
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
          {{ recentFailuresText(issue.recent_failures) }}
        </gl-badge>
        {{ issue.name }}
      </button>
    </div>
  </div>
</template>
