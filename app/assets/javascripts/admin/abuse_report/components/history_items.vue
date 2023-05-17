<script>
import { GlSprintf } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import HistoryItem from '~/vue_shared/components/registry/history_item.vue';
import { HISTORY_ITEMS_I18N } from '../constants';

export default {
  name: 'HistoryItems',
  components: {
    GlSprintf,
    TimeAgoTooltip,
    HistoryItem,
  },
  props: {
    report: {
      type: Object,
      required: true,
    },
    reporter: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    reporterName() {
      return this.reporter?.name || this.$options.i18n.deletedReporter;
    },
  },
  i18n: HISTORY_ITEMS_I18N,
};
</script>

<template>
  <!-- The styles `issuable-discussion`, `timeline`, `main-notes-list` and `notes` used below
       are declared in app/assets/stylesheets/pages/notes.scss -->
  <section class="gl-pt-6 issuable-discussion">
    <h2 class="gl-font-size-h1 gl-mt-0 gl-mb-2">{{ $options.i18n.activity }}</h2>
    <ul class="timeline main-notes-list notes">
      <history-item icon="warning">
        <div class="gl-display-flex gl-xs-flex-direction-column">
          <gl-sprintf :message="$options.i18n.reportedByForCategory">
            <template #name>{{ reporterName }}</template>
            <template #category>{{ report.category }}</template>
          </gl-sprintf>
          <time-ago-tooltip :time="report.reportedAt" class="gl-text-secondary gl-sm-ml-3" />
        </div>
      </history-item>
    </ul>
  </section>
</template>
