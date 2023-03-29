<script>
import { uniqueId } from 'lodash';
import { GlButton, GlCollapse } from '@gitlab/ui';
import { getTimeago } from '~/lib/utils/datetime_utility';
import { __, sprintf } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  components: {
    GlButton,
    GlCollapse,
  },
  directives: { SafeHtml },
  props: {
    report: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isVisible: false,
      collapseId: uniqueId('abuse-report-detail-'),
    };
  },
  computed: {
    toggleText() {
      return this.isVisible ? __('Hide details') : __('Show details');
    },
    reportedUserCreatedAt() {
      const { reportedUser } = this.report;
      return sprintf(__('User joined %{timeAgo}'), {
        timeAgo: getTimeago().format(reportedUser.createdAt),
      });
    },
  },
  methods: {
    toggleCollapse() {
      this.isVisible = !this.isVisible;
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-flex-direction-column">
    <gl-collapse :id="collapseId" v-model="isVisible">
      <dl class="gl-mb-2">
        <dd>{{ reportedUserCreatedAt }}</dd>

        <dt>{{ __('Message') }}</dt>
        <dd v-safe-html="report.message"></dd>
      </dl>
    </gl-collapse>
    <div>
      <gl-button
        :aria-expanded="`${isVisible}`"
        :aria-controls="collapseId"
        size="small"
        variant="link"
        @click="toggleCollapse"
        >{{ toggleText }}
      </gl-button>
    </div>
  </div>
</template>
