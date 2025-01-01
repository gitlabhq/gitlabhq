<script>
import { GlAvatarLabeled, GlLink, GlTableLite } from '@gitlab/ui';
import { isEmpty, maxBy, range } from 'lodash';
import { __, sprintf } from '~/locale';
import {
  INFO_LABEL,
  ID_LABEL,
  STATUS_LABEL,
  EXPERIMENT_LABEL,
  ARTIFACTS_LABEL,
  PARAMETERS_LABEL,
  METADATA_LABEL,
  MLFLOW_ID_LABEL,
  CI_SECTION_LABEL,
  JOB_LABEL,
  CI_USER_LABEL,
  CI_MR_LABEL,
  PERFORMANCE_LABEL,
  NO_PARAMETERS_MESSAGE,
  NO_METRICS_MESSAGE,
  NO_METADATA_MESSAGE,
  NO_CI_MESSAGE,
} from '../translations';
import DetailRow from './candidate_detail_row.vue';

export default {
  HEADER_CLASSES: ['gl-text-lg', 'gl-mt-5'],
  name: 'MlCandidateDetail',
  components: {
    DetailRow,
    GlAvatarLabeled,
    GlLink,
    GlTableLite,
  },
  props: {
    candidate: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    INFO_LABEL,
    ID_LABEL,
    STATUS_LABEL,
    EXPERIMENT_LABEL,
    ARTIFACTS_LABEL,
    MLFLOW_ID_LABEL,
    CI_SECTION_LABEL,
    JOB_LABEL,
    CI_USER_LABEL,
    CI_MR_LABEL,
    PARAMETERS_LABEL,
    METADATA_LABEL,
    PERFORMANCE_LABEL,
    NO_PARAMETERS_MESSAGE,
    NO_METRICS_MESSAGE,
    NO_METADATA_MESSAGE,
    NO_CI_MESSAGE,
  },
  computed: {
    info() {
      return Object.freeze(this.candidate.info);
    },
    ciJob() {
      return Object.freeze(this.info.ciJob);
    },
    hasMetadata() {
      return !isEmpty(this.candidate.metadata);
    },
    hasParameters() {
      return !isEmpty(this.candidate.params);
    },
    hasMetrics() {
      return !isEmpty(this.candidate.metrics);
    },
    metricsTableFields() {
      const maxStep = maxBy(this.candidate.metrics, 'step').step;
      const rowClass = '!gl-p-3';

      const cssClasses = { thClass: rowClass, tdClass: rowClass };

      const fields = range(maxStep + 1).map((step) => ({
        key: step.toString(),
        label: sprintf(__('Step %{step}'), { step }),
        ...cssClasses,
      }));

      return [{ key: 'name', label: __('Metric'), ...cssClasses }, ...fields];
    },
    metricsTableItems() {
      const items = {};
      this.candidate.metrics.forEach((metric) => {
        const metricRow = items[metric.name] || { name: metric.name };
        metricRow[metric.step] = metric.value;
        items[metric.name] = metricRow;
      });

      return Object.values(items);
    },
  },
};
</script>

<template>
  <div>
    <section class="gl-mb-6">
      <h3 :class="$options.HEADER_CLASSES">{{ $options.i18n.CI_SECTION_LABEL }}</h3>

      <table v-if="ciJob" class="candidate-details">
        <tbody>
          <detail-row
            :label="$options.i18n.JOB_LABEL"
            :section-label="$options.i18n.CI_SECTION_LABEL"
          >
            <gl-link :href="ciJob.path">
              {{ ciJob.name }}
            </gl-link>
          </detail-row>

          <detail-row v-if="ciJob.user" :label="$options.i18n.CI_USER_LABEL">
            <gl-avatar-labeled label="" :size="24" :src="ciJob.user.avatar">
              <gl-link :href="ciJob.user.path">
                {{ ciJob.user.name }}
              </gl-link>
            </gl-avatar-labeled>
          </detail-row>

          <detail-row v-if="ciJob.mergeRequest" :label="$options.i18n.CI_MR_LABEL">
            <gl-link :href="ciJob.mergeRequest.path">
              !{{ ciJob.mergeRequest.iid }} {{ ciJob.mergeRequest.title }}
            </gl-link>
          </detail-row>
        </tbody>
      </table>

      <div v-else class="gl-text-subtle">{{ $options.i18n.NO_CI_MESSAGE }}</div>
    </section>

    <section class="gl-mb-6">
      <h3 :class="$options.HEADER_CLASSES">{{ $options.i18n.PARAMETERS_LABEL }}</h3>

      <table v-if="hasParameters" class="candidate-details">
        <tbody>
          <detail-row v-for="item in candidate.params" :key="item.name" :label="item.name">
            {{ item.value }}
          </detail-row>
        </tbody>
      </table>

      <div v-else class="gl-text-subtle">{{ $options.i18n.NO_PARAMETERS_MESSAGE }}</div>
    </section>

    <section class="gl-mb-6">
      <h3 :class="$options.HEADER_CLASSES">{{ $options.i18n.METADATA_LABEL }}</h3>

      <table v-if="hasMetadata" class="candidate-details">
        <tbody>
          <detail-row v-for="item in candidate.metadata" :key="item.name" :label="item.name">
            {{ item.value }}
          </detail-row>
        </tbody>
      </table>

      <div v-else class="gl-text-subtle">{{ $options.i18n.NO_METADATA_MESSAGE }}</div>
    </section>

    <section class="gl-mb-6">
      <h3 :class="$options.HEADER_CLASSES">{{ $options.i18n.PERFORMANCE_LABEL }}</h3>

      <div v-if="hasMetrics" class="gl-overflow-x-auto">
        <gl-table-lite
          :items="metricsTableItems"
          :fields="metricsTableFields"
          class="gl-w-auto"
          hover
        />
      </div>

      <div v-else class="gl-text-subtle">{{ $options.i18n.NO_METRICS_MESSAGE }}</div>
    </section>
  </div>
</template>
