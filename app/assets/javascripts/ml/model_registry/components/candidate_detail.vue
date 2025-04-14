<script>
import { GlAvatarLabeled, GlLink, GlTableLite } from '@gitlab/ui';
import { isEmpty, maxBy, range } from 'lodash';
import { __, s__, sprintf } from '~/locale';
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
    ciSectionLabel: s__('MlModelRegistry|CI Info'),
    jobLabel: __('Job'),
    ciUserLabel: s__('MlModelRegistry|Triggered by'),
    ciMrLabel: __('Merge request'),
    parametersLabel: s__('MlModelRegistry|Parameters'),
    metadataLabel: s__('MlModelRegistry|Metadata'),
    performanceLabel: s__('MlModelRegistry|Performance'),
    noParametersMessage: s__('MlModelRegistry|No logged parameters'),
    noMetricsMessage: s__('MlModelRegistry|No logged metrics'),
    noMetadataMessage: s__('MlModelRegistry|No logged metadata'),
    noCiMessage: s__('MlModelRegistry|Run not linked to a CI build'),
  },
  computed: {
    info() {
      return this.candidate.info;
    },
    ciJob() {
      return this.info.ciJob;
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
      <h3 :class="$options.HEADER_CLASSES">{{ $options.i18n.ciSectionLabel }}</h3>

      <table v-if="ciJob" class="candidate-details">
        <tbody>
          <detail-row :label="$options.i18n.jobLabel" :section-label="$options.i18n.ciSectionLabel">
            <gl-link :href="ciJob.path">
              {{ ciJob.name }}
            </gl-link>
          </detail-row>

          <detail-row v-if="ciJob.user" :label="$options.i18n.ciUserLabel">
            <gl-avatar-labeled label="" :size="24" :src="ciJob.user.avatar">
              <gl-link :href="ciJob.user.path">
                {{ ciJob.user.name }}
              </gl-link>
            </gl-avatar-labeled>
          </detail-row>

          <detail-row v-if="ciJob.mergeRequest" :label="$options.i18n.ciMrLabel">
            <gl-link :href="ciJob.mergeRequest.path">
              !{{ ciJob.mergeRequest.iid }} {{ ciJob.mergeRequest.title }}
            </gl-link>
          </detail-row>
        </tbody>
      </table>

      <div v-else class="gl-text-subtle">{{ $options.i18n.noCiMessage }}</div>
    </section>

    <section class="gl-mb-6">
      <h3 :class="$options.HEADER_CLASSES">{{ $options.i18n.parametersLabel }}</h3>

      <table v-if="hasParameters" class="candidate-details">
        <tbody>
          <detail-row v-for="item in candidate.params" :key="item.name" :label="item.name">
            {{ item.value }}
          </detail-row>
        </tbody>
      </table>

      <div v-else class="gl-text-subtle">{{ $options.i18n.noParametersMessage }}</div>
    </section>

    <section class="gl-mb-6">
      <h3 :class="$options.HEADER_CLASSES">{{ $options.i18n.metadataLabel }}</h3>

      <table v-if="hasMetadata" class="candidate-details">
        <tbody>
          <detail-row v-for="item in candidate.metadata" :key="item.name" :label="item.name">
            {{ item.value }}
          </detail-row>
        </tbody>
      </table>

      <div v-else class="gl-text-subtle">{{ $options.i18n.noMetadataMessage }}</div>
    </section>

    <section class="gl-mb-6">
      <h3 :class="$options.HEADER_CLASSES">{{ $options.i18n.performanceLabel }}</h3>

      <div v-if="hasMetrics" class="gl-overflow-x-auto">
        <gl-table-lite
          :items="metricsTableItems"
          :fields="metricsTableFields"
          class="gl-w-auto"
          hover
        />
      </div>

      <div v-else class="gl-text-subtle">{{ $options.i18n.noMetricsMessage }}</div>
    </section>
  </div>
</template>
