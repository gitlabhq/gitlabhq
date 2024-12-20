<script>
import { isEmpty } from 'lodash';
import { GlTableLite } from '@gitlab/ui';
import * as translations from '~/ml/experiment_tracking/routes/experiments/show/translations';
import { s__ } from '~/locale';

export default {
  name: 'ExperimentMetadata',
  components: { GlTableLite },
  props: {
    experiment: {
      type: Object,
      required: true,
    },
  },
  computed: {
    hasMetadata() {
      return !isEmpty(this.experiment.metadata);
    },
  },
  fields: [
    {
      key: 'name',
      label: s__('MlExperimentTracking|Key'),
      thClass: 'gl-w-1/3',
      tdClass: 'gl-content-center',
    },
    {
      key: 'value',
      label: s__('MlExperimentTracking|Value'),
      thClass: 'gl-w-2/3',
      tdClass: 'gl-content-center',
    },
  ],
  i18n: translations,
};
</script>

<template>
  <section>
    <div class="experiment-metadata">
      <h3 class="gl-heading-3" data-testid="metadata-header">{{ $options.i18n.METADATA_LABEL }}</h3>

      <gl-table-lite
        v-if="hasMetadata"
        :items="experiment.metadata"
        :fields="$options.fields"
        responsive
      >
        <template #cell(name)="{ item: { name } }">{{ name }}</template>
        <template #cell(value)="{ item: { value } }">{{ value }}</template>
      </gl-table-lite>
      <div v-else class="gl-text-subtle" data-testid="metadata-empty-state">
        {{ $options.i18n.NO_METADATA_MESSAGE }}
      </div>
    </div>
  </section>
</template>
