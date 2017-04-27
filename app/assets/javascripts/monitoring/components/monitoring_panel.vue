<script>
import MonitoringRow from './monitoring_row.vue';
/*
This component renders a panel for each group of the correspondent metrics
previously configured
*/
export default {
  props: {
    groupData: {
      type: Object,
      required: true,
      default: {},
    },
  },
  components: {
    'monitoring-row': MonitoringRow
  }
};
</script>
<template>
  <div class="row">
    <div class="col-md-12">
      <div class="panel panel-default prometheus-panel">
        <div class="panel-heading">
          <h4>{{groupData.group}}</h4>
        </div>
        <div class="panel-body">
          <monitoring-row
            v-for="(row, index) in groupData.metrics"
            :rowData="row"
            :key="index"
          />
        </div>
      </div>
    </div>
  </div>
</template>
