<script>
import { GlFormSelect } from '@gitlab/ui';

export default {
  name: 'RequestSelector',
  components: {
    GlFormSelect,
  },
  props: {
    currentRequest: {
      type: Object,
      required: true,
    },
    requests: {
      type: Array,
      required: true,
    },
  },
  emits: ['change-current-request'],
  data() {
    return {
      currentRequestId: this.currentRequest.id,
    };
  },
  watch: {
    currentRequestId(newRequestId) {
      this.$emit('change-current-request', newRequestId);
    },
  },
};
</script>
<template>
  <div id="peek-request-selector" data-testid="request-dropdown" class="view gl-mr-5">
    <gl-form-select
      v-model="currentRequestId"
      select-class="gl-bg-alpha-light-24 gl-text-neutral-0 gl-w-26"
    >
      <option
        v-for="request in requests"
        :key="request.id"
        :value="request.id"
        data-testid="request-dropdown-option"
      >
        {{ request.displayName }}
      </option>
    </gl-form-select>
  </div>
</template>
