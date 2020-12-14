<script>
import { GlLoadingIcon } from '@gitlab/ui';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import STATUS_MAP from '../constants';

export default {
  name: 'ImportStatus',
  components: {
    CiIcon,
    GlLoadingIcon,
  },
  props: {
    status: {
      type: String,
      required: true,
    },
  },

  computed: {
    mappedStatus() {
      return STATUS_MAP[this.status];
    },

    ciIconStatus() {
      const { icon } = this.mappedStatus;

      return {
        icon: `status_${icon}`,
        group: icon,
      };
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon
      v-if="mappedStatus.loadingIcon"
      :inline="true"
      :class="mappedStatus.textClass"
      class="align-middle mr-2"
    />
    <ci-icon v-else css-classes="align-middle mr-2" :status="ciIconStatus" />
    <span :class="mappedStatus.textClass">{{ mappedStatus.text }}</span>
  </div>
</template>
