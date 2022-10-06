<script>
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import getPipelineSchedulesQuery from '../graphql/queries/get_pipeline_schedules.query.graphql';
import PipelineSchedulesTable from './table/pipeline_schedules_table.vue';

export default {
  i18n: {
    schedulesFetchError: s__('PipelineSchedules|There was a problem fetching pipeline schedules.'),
  },
  components: {
    GlAlert,
    GlLoadingIcon,
    PipelineSchedulesTable,
  },
  inject: {
    fullPath: {
      default: '',
    },
  },
  apollo: {
    schedules: {
      query: getPipelineSchedulesQuery,
      variables() {
        return {
          projectPath: this.fullPath,
        };
      },
      update({ project }) {
        return project?.pipelineSchedules?.nodes || [];
      },
      error() {
        this.hasError = true;
      },
    },
  },
  data() {
    return {
      schedules: [],
      hasError: false,
      errorDismissed: false,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.schedules.loading;
    },
    showError() {
      return this.hasError && !this.errorDismissed;
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="showError" class="gl-mb-2" variant="danger" @dismiss="errorDismissed = true">
      {{ $options.i18n.schedulesFetchError }}
    </gl-alert>

    <gl-loading-icon v-if="isLoading" size="lg" />

    <!-- Tabs will be addressed in #371989 -->

    <pipeline-schedules-table v-else :schedules="schedules" />
  </div>
</template>
