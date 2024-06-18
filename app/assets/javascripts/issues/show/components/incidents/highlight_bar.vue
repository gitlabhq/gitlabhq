<script>
import { GlLink, GlTooltipDirective } from '@gitlab/ui';
import { formatDate } from '~/lib/utils/datetime_utility';

export default {
  components: {
    GlLink,
    IncidentSla: () => import('ee_component/issues/show/components/incidents/incident_sla.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    alert: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return { childHasData: false };
  },
  computed: {
    startTime() {
      return formatDate(this.alert.startedAt, 'yyyy-mm-dd Z');
    },
    showHighlightBar() {
      return this.alert || this.childHasData;
    },
  },
  methods: {
    update(hasData) {
      this.childHasData = hasData;
    },
  },
};
</script>

<template>
  <div
    v-show="showHighlightBar"
    class="gl-border-solid gl-border-1 gl-border-gray-100 gl-p-5 gl-mb-3 gl-rounded-base gl-display-flex gl-justify-content-space-between gl-flex-direction-column gl-sm-flex-direction-row"
  >
    <div v-if="alert" class="gl-mr-3">
      <span class="gl-font-bold">{{ s__('HighlightBar|Original alert:') }}</span>
      <gl-link v-gl-tooltip :title="alert.title" :href="alert.detailsUrl">
        #{{ alert.iid }}
      </gl-link>
    </div>

    <div v-if="alert" class="gl-mr-3">
      <span class="gl-font-bold">{{ s__('HighlightBar|Alert start time:') }}</span>
      {{ startTime }}
    </div>

    <div v-if="alert" class="gl-mr-3">
      <span class="gl-font-bold">{{ s__('HighlightBar|Alert events:') }}</span>
      <span>{{ alert.eventCount }}</span>
    </div>

    <incident-sla @update="update" />
  </div>
</template>
