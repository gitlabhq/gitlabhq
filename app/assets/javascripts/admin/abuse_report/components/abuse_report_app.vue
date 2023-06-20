<script>
import { GlAlert } from '@gitlab/ui';
import ReportHeader from './report_header.vue';
import UserDetails from './user_details.vue';
import ReportedContent from './reported_content.vue';
import HistoryItems from './history_items.vue';

const alertDefaults = {
  visible: false,
  variant: '',
  message: '',
};

export default {
  name: 'AbuseReportApp',
  components: {
    GlAlert,
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
  data() {
    return {
      alert: { ...alertDefaults },
    };
  },
  methods: {
    showAlert(variant, message) {
      this.alert.visible = true;
      this.alert.variant = variant;
      this.alert.message = message;
    },
    closeAlert() {
      this.alert = { ...alertDefaults };
    },
  },
};
</script>

<template>
  <section>
    <gl-alert v-if="alert.visible" :variant="alert.variant" class="gl-mt-4" @dismiss="closeAlert">{{
      alert.message
    }}</gl-alert>
    <report-header
      v-if="abuseReport.user"
      :user="abuseReport.user"
      :report="abuseReport.report"
      @showAlert="showAlert"
    />
    <user-details v-if="abuseReport.user" :user="abuseReport.user" />
    <reported-content :report="abuseReport.report" :reporter="abuseReport.reporter" />
    <history-items :report="abuseReport.report" :reporter="abuseReport.reporter" />
  </section>
</template>
