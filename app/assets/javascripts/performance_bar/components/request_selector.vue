<script>
export default {
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
  <div id="peek-request-selector" data-qa-selector="request_dropdown" class="view">
    <select v-model="currentRequestId">
      <option
        v-for="request in requests"
        :key="request.id"
        :value="request.id"
        data-qa-selector="request_dropdown_option"
      >
        {{ request.displayName }}
      </option>
    </select>
  </div>
</template>
