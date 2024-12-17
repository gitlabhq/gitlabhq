<script>
import {
  GlBadge,
  GlTruncate,
  GlButton,
  GlTooltipDirective,
  GlLoadingIcon,
  GlAlert,
} from '@gitlab/ui';
import { stringify } from 'yaml';
import { s__ } from '~/locale';
import PodLogsButton from '~/environments/environment_details/components/kubernetes/pod_logs_button.vue';
import getK8sEventsQuery from '~/environments/graphql/queries/k8s_events.query.graphql';
import {
  WORKLOAD_STATUS_BADGE_VARIANTS,
  STATUS_LABELS,
  WORKLOAD_DETAILS_SECTIONS as SECTIONS,
} from '../constants';
import WorkloadDetailsItem from './workload_details_item.vue';
import K8sEventItem from './k8s_event_item.vue';

export default {
  components: {
    GlBadge,
    GlTruncate,
    GlButton,
    GlLoadingIcon,
    GlAlert,
    WorkloadDetailsItem,
    PodLogsButton,
    K8sEventItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    configuration: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    item: {
      type: Object,
      required: true,
      validator: (item) => ['name', 'kind', 'labels', 'annotations'].every((key) => item[key]),
    },
    selectedSection: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return { eventsError: null, eventsLoading: false, k8sEvents: [] };
  },
  apollo: {
    k8sEvents: {
      query: getK8sEventsQuery,
      variables() {
        return {
          configuration: this.configuration,
          involvedObjectName: this.item.name,
          namespace: this.item.namespace,
        };
      },
      skip() {
        return Boolean(!Object.keys(this.configuration).length);
      },
      error(err) {
        this.eventsError = err.message;
      },
      watchLoading(isLoading) {
        this.eventsLoading = isLoading;
      },
      update(data) {
        return data?.k8sEvents
          ?.map((event) => ({
            ...event,
            timestamp: event.lastTimestamp || event.eventTime,
          }))
          .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
      },
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
    hasContainers() {
      return Boolean(this.item.containers);
    },
    hasActions() {
      return Boolean(this.item.actions?.length);
    },
    expanded() {
      return {
        status: this.selectedSection === SECTIONS.STATUS,
      };
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
    getContainersProp(container) {
      return [container];
    },
  },
  i18n: {
    name: s__('KubernetesDashboard|Name'),
    actions: s__('KubernetesDashboard|Actions'),
    kind: s__('KubernetesDashboard|Kind'),
    labels: s__('KubernetesDashboard|Labels'),
    status: s__('KubernetesDashboard|Status'),
    annotations: s__('KubernetesDashboard|Annotations'),
    spec: s__('KubernetesDashboard|Spec'),
    containers: s__('KubernetesDashboard|Containers'),
    events: s__('KubernetesDashboard|Events'),
    eventsEmptyText: s__('KubernetesDashboard|No events available'),
  },
  WORKLOAD_STATUS_BADGE_VARIANTS,
  STATUS_LABELS,
};
</script>

<template>
  <ul class="gl-list-none">
    <workload-details-item :label="$options.i18n.name">
      <span class="gl-break-anywhere"> {{ item.name }}</span>
    </workload-details-item>
    <workload-details-item v-if="hasActions" :label="$options.i18n.actions">
      <span v-for="action of item.actions" :key="action.name">
        <gl-button
          v-gl-tooltip
          :title="action.text"
          :aria-label="action.text"
          :variant="action.variant"
          :icon="action.icon"
          category="secondary"
          class="gl-mr-3"
          @click="$emit(action.name, item)"
        />
      </span>
    </workload-details-item>
    <workload-details-item :label="$options.i18n.kind">
      {{ item.kind }}
    </workload-details-item>
    <workload-details-item v-if="itemLabels.length" :label="$options.i18n.labels">
      <div class="gl-flex gl-flex-wrap gl-gap-2">
        <gl-badge v-for="label of itemLabels" :key="label" class="gl-w-auto gl-max-w-full">
          <gl-truncate :text="label" with-tooltip />
        </gl-badge>
      </div>
    </workload-details-item>
    <workload-details-item v-if="item.status && !item.fullStatus" :label="$options.i18n.status">
      <gl-badge :variant="$options.WORKLOAD_STATUS_BADGE_VARIANTS[item.status]">{{
        $options.STATUS_LABELS[item.status]
      }}</gl-badge>
    </workload-details-item>
    <workload-details-item
      v-if="item.fullStatus"
      :label="$options.i18n.status"
      :is-expanded="expanded.status"
      collapsible
    >
      <template v-if="item.status" #label>
        <span class="gl-mr-2 gl-font-bold">{{ $options.i18n.status }}</span>
        <gl-badge :variant="$options.WORKLOAD_STATUS_BADGE_VARIANTS[item.status]">{{
          $options.STATUS_LABELS[item.status]
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
    <workload-details-item v-if="hasContainers" :label="$options.i18n.containers">
      <div
        v-for="(container, index) of item.containers"
        :key="index"
        class="gl-flex gl-items-center gl-justify-between gl-px-5 gl-py-3"
        :class="{
          'gl-border-t-1 gl-border-t-default gl-border-t-solid': index > 0,
        }"
      >
        {{ container.name }}
        <pod-logs-button
          :pod-name="item.name"
          :namespace="item.namespace"
          :containers="getContainersProp(container)"
        />
      </div>
    </workload-details-item>
    <workload-details-item :label="$options.i18n.events" collapsible>
      <gl-loading-icon v-if="eventsLoading" inline />
      <gl-alert v-else-if="eventsError" variant="danger" :dismissible="false">
        {{ eventsError }}
      </gl-alert>
      <div v-else-if="k8sEvents.length" class="issuable-discussion">
        <ul class="notes main-notes-list timeline -gl-ml-2">
          <k8s-event-item v-for="(event, index) in k8sEvents" :key="index" :event="event" />
        </ul>
      </div>
      <span v-else class="gl-text-subtle">{{ $options.i18n.eventsEmptyText }}</span>
    </workload-details-item>
  </ul>
</template>
