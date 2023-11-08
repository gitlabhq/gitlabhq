<script>
import { GlAlert } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ReportHeader from './report_header.vue';
import UserDetails from './user_details.vue';
import ReportDetails from './report_details.vue';
import ReportedContent from './reported_content.vue';
import ActivityEventsList from './activity_events_list.vue';
import ActivityHistoryItem from './activity_history_item.vue';
import AbuseReportNotes from './abuse_report_notes.vue';

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
    ReportDetails,
    ReportedContent,
    ActivityEventsList,
    ActivityHistoryItem,
    AbuseReportNotes,
  },
  mixins: [glFeatureFlagsMixin()],
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
  computed: {
    similarOpenReports() {
      return this.abuseReport.user?.similarOpenReports || [];
    },
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

    <report-details
      v-if="glFeatures.abuseReportLabels"
      :report-id="abuseReport.report.globalId"
      class="gl-mt-6"
    />

    <reported-content :report="abuseReport.report" data-testid="reported-content" />

    <div
      v-for="report in similarOpenReports"
      :key="report.id"
      data-testid="reported-content-similar-open-reports"
    >
      <reported-content :report="report" />
    </div>

    <activity-events-list>
      <template #history-items>
        <activity-history-item :report="abuseReport.report" data-testid="activity" />
        <activity-history-item
          v-for="report in similarOpenReports"
          :key="report.id"
          :report="report"
          data-testid="activity-similar-open-reports"
        />
      </template>
    </activity-events-list>

    <abuse-report-notes
      v-if="glFeatures.abuseReportNotes"
      :abuse-report-id="abuseReport.report.globalId"
    />
  </section>
</template>
