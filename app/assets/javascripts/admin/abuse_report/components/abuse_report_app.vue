<script>
import ReportHeader from './report_header.vue';
import UserDetails from './user_details.vue';
import ReportedContent from './reported_content.vue';
import HistoryItems from './history_items.vue';

export default {
  name: 'AbuseReportApp',
  components: {
    ReportHeader,
    UserDetails,
    ReportedContent,
    HistoryItems,
  },
  props: {
    abuseReport: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <section>
    <report-header
      v-if="abuseReport.user"
      :user="abuseReport.user"
      :actions="abuseReport.actions"
    />
    <user-details v-if="abuseReport.user" :user="abuseReport.user" />
    <reported-content :report="abuseReport.report" :reporter="abuseReport.reporter" />
    <history-items :report="abuseReport.report" :reporter="abuseReport.reporter" />
  </section>
</template>
