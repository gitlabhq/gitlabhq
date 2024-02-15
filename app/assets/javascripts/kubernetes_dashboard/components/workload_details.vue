<script>
import { GlBadge, GlTruncate } from '@gitlab/ui';
import { stringify } from 'yaml';
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
      validator: (item) => ['name', 'kind', 'labels', 'annotations'].every((key) => item[key]),
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
    specYaml() {
      return this.getYamlStringFromJSON(this.item.spec);
    },
    statusYaml() {
      return this.getYamlStringFromJSON(this.item.fullStatus);
    },
    annotationsYaml() {
      return this.getYamlStringFromJSON(this.item.annotations);
    },
    hasFullStatus() {
      return Boolean(this.item.fullStatus);
    },
  },
  methods: {
    getLabelBadgeText([key, value]) {
      return `${key}=${value}`;
    },

    getAnnotationsText([key, value]) {
      return `${key}: ${value}`;
    },
    getYamlStringFromJSON(json) {
      if (!json) {
        return '';
      }
      return stringify(json);
    },
  },
  i18n: {
    name: s__('KubernetesDashboard|Name'),
    kind: s__('KubernetesDashboard|Kind'),
    labels: s__('KubernetesDashboard|Labels'),
    status: s__('KubernetesDashboard|Status'),
    annotations: s__('KubernetesDashboard|Annotations'),
    spec: s__('KubernetesDashboard|Spec'),
  },
  WORKLOAD_STATUS_BADGE_VARIANTS,
};
</script>

<template>
  <ul class="gl-list-style-none">
    <workload-details-item :label="$options.i18n.name">
      <span class="gl-word-break-word"> {{ item.name }}</span>
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
    <workload-details-item v-if="item.status && !item.fullStatus" :label="$options.i18n.status">
      <gl-badge :variant="$options.WORKLOAD_STATUS_BADGE_VARIANTS[item.status]" size="sm">{{
        item.status
      }}</gl-badge>
    </workload-details-item>
    <workload-details-item v-if="item.fullStatus" :label="$options.i18n.status" collapsible>
      <template v-if="item.status" #label>
        <span class="gl-mr-2 gl-font-weight-bold">{{ $options.i18n.status }}</span>
        <gl-badge :variant="$options.WORKLOAD_STATUS_BADGE_VARIANTS[item.status]" size="sm">{{
          item.status
        }}</gl-badge>
      </template>
      <pre>{{ statusYaml }}</pre>
    </workload-details-item>
    <workload-details-item
      v-if="itemAnnotations.length"
      :label="$options.i18n.annotations"
      collapsible
    >
      <pre>{{ annotationsYaml }}</pre>
    </workload-details-item>
    <workload-details-item v-if="item.spec" :label="$options.i18n.spec" collapsible>
      <pre>{{ specYaml }}</pre>
    </workload-details-item>
  </ul>
</template>
