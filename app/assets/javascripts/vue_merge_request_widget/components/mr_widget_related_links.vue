<script>
import { GlLink } from '@gitlab/ui';
import { STATUS_CLOSED, STATUS_MERGED } from '~/issues/constants';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { s__, n__ } from '~/locale';

export default {
  name: 'MRWidgetRelatedLinks',
  directives: {
    SafeHtml,
  },
  components: {
    GlLink,
  },
  props: {
    relatedLinks: {
      type: Object,
      required: true,
      default: () => ({}),
    },
    state: {
      type: String,
      required: false,
      default: '',
    },
    showAssignToMe: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    closesText() {
      if (this.state === STATUS_MERGED) {
        return s__('mrWidget|Closed');
      }
      if (this.state === STATUS_CLOSED) {
        return s__('mrWidget|Did not close');
      }

      return n__('mrWidget|Closes issue', 'mrWidget|Closes issues', this.relatedLinks.closingCount);
    },
    assignIssueText() {
      if (this.relatedLinks.unassignedCount > 1) {
        return s__('mrWidget|Assign yourself to these issues');
      }
      return s__('mrWidget|Assign yourself to this issue');
    },
    shouldShowAssignToMeLink() {
      return (
        this.relatedLinks.unassignedCount && this.relatedLinks.assignToMe && this.showAssignToMe
      );
    },
  },
};
</script>
<template>
  <section>
    <p v-if="relatedLinks.closing" class="gl-m-0 gl-inline !gl-text-sm">
      {{ closesText }}
      <span v-safe-html="relatedLinks.closing"></span>
    </p>
    <p v-if="relatedLinks.mentioned" class="gl-m-0 gl-inline !gl-text-sm">
      <span v-if="relatedLinks.closing">&middot;</span>
      {{ n__('mrWidget|Mentions issue', 'mrWidget|Mentions issues', relatedLinks.mentionedCount) }}
      <span v-safe-html="relatedLinks.mentioned"></span>
    </p>
    <p v-if="shouldShowAssignToMeLink" class="gl-m-0 gl-inline !gl-text-sm">
      <span>
        <gl-link rel="nofollow" data-method="post" :href="relatedLinks.assignToMe">{{
          assignIssueText
        }}</gl-link>
      </span>
    </p>
  </section>
</template>
