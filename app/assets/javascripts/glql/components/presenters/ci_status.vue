<script>
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { ciStatusToIcon } from './utils/ci';

export default {
  name: 'CiStatusPresenter',
  components: {
    CiIcon,
  },
  props: {
    data: {
      required: true,
      type: String,
    },
  },
  computed: {
    status() {
      return ciStatusToIcon(this.data);
    },
  },
};
</script>
<template>
  <ci-icon v-if="status" :status="status" :use-link="false" show-status-text />
  <span v-else>{{ data }}</span>
</template>
