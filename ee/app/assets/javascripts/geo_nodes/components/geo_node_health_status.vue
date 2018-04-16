<script>
  import icon from '~/vue_shared/components/icon.vue';
  import { HEALTH_STATUS_ICON } from '../constants';

  export default {
    components: {
      icon,
    },
    props: {
      status: {
        type: String,
        required: true,
      },
    },
    computed: {
      healthCssClass() {
        return `geo-node-${this.status.toLowerCase()}`;
      },
      statusIconName() {
        return HEALTH_STATUS_ICON[this.status.toLowerCase()];
      },
    },
  };
</script>

<template>
  <div class="prepend-top-15 detail-section-item">
    <div class="node-detail-title">
      {{ s__('GeoNodes|Health status:') }}
    </div>
    <div
      class="node-detail-value node-health-status"
      :class="healthCssClass"
    >
      <icon
        :size="16"
        :name="statusIconName"
      />
      <span
        class="status-text prepend-left-5"
      >
        {{ status }}
      </span>
    </div>
  </div>
</template>
