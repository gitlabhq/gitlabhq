<script>
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import abuseReportQuery from '../graphql/abuse_report.query.graphql';
import LabelsSelect from './labels_select.vue';

export default {
  name: 'ReportDetails',
  components: {
    LabelsSelect,
  },
  props: {
    reportId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      report: { labels: [] },
    };
  },
  apollo: {
    report: {
      query() {
        return abuseReportQuery;
      },
      variables() {
        return { id: this.reportId };
      },
      update({ abuseReport }) {
        return {
          labels: abuseReport.labels?.nodes,
        };
      },
      error() {
        createAlert({ message: this.$options.i18n.fetchError });
      },
    },
  },
  i18n: {
    fetchError: __('An error occurred while fetching labels, please try again.'),
  },
};
</script>

<template>
  <labels-select :report="report" />
</template>
