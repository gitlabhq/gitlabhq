<script>
import { GlBadge, GlTruncate } from '@gitlab/ui';
import { s__ } from '~/locale';
import { WORKLOAD_STATUS_BADGE_VARIANTS } from '../constants';
import WorkloadDetailsItem from './workload_details_item.vue';

export default {
  components: {
    GlBadge,
    GlTruncate,
    WorkloadDetailsItem,
  },
  props: {
    item: {
      type: Object,
      required: true,
      validator: (item) =>
        ['name', 'kind', 'labels', 'annotations', 'status'].every((key) => item[key]),
    },
  },
  computed: {
    itemLabels() {
      const { labels } = this.item;
      return Object.entries(labels).map(this.getLabelBadgeText);
    },
    itemAnnotations() {
      const { annotations } = this.item;
      return Object.entries(annotations).map(this.getAnnotationsText);
    },
  },
  methods: {
    getLabelBadgeText([key, value]) {
      return `${key}=${value}`;
    },

    getAnnotationsText([key, value]) {
      return `${key}: ${value}`;
    },
  },
  i18n: {
    name: s__('KubernetesDashboard|Name'),
    kind: s__('KubernetesDashboard|Kind'),
    labels: s__('KubernetesDashboard|Labels'),
    status: s__('KubernetesDashboard|Status'),
    annotations: s__('KubernetesDashboard|Annotations'),
  },
  WORKLOAD_STATUS_BADGE_VARIANTS,
};
</script>

<template>
  <ul class="gl-list-style-none">
    <workload-details-item :label="$options.i18n.name">
      {{ item.name }}
    </workload-details-item>
    <workload-details-item :label="$options.i18n.kind">
      {{ item.kind }}
    </workload-details-item>
    <workload-details-item v-if="itemLabels.length" :label="$options.i18n.labels">
      <div class="gl-display-flex gl-flex-wrap gl-gap-2">
        <gl-badge v-for="label of itemLabels" :key="label" class="gl-max-w-full">
          <gl-truncate :text="label" with-tooltip />
        </gl-badge>
      </div>
    </workload-details-item>
    <workload-details-item :label="$options.i18n.status">
      <gl-badge :variant="$options.WORKLOAD_STATUS_BADGE_VARIANTS[item.status]">{{
        item.status
      }}</gl-badge></workload-details-item
    >
    <workload-details-item v-if="itemAnnotations.length" :label="$options.i18n.annotations">
      <p
        v-for="annotation of itemAnnotations"
        :key="annotation"
        class="gl-mb-2 gl-overflow-wrap-anywhere"
      >
        {{ annotation }}
      </p>
    </workload-details-item>
  </ul>
</template>
