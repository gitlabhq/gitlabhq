<script>
import ChildEmittingCamelCaseEvent from './child_emitting_camel_case_event.vue';

export default {
  name: 'ParentWithCamelCaseEventHandler',
  components: { ChildEmittingCamelCaseEvent },
  data() {
    return {
      received: false,
      payload: '',
    };
  },
  methods: {
    handleEvent(payload) {
      this.received = true;
      this.payload = payload;
    },
  },
};
</script>

<template>
  <div>
    <!-- eslint-disable-next-line vue/v-on-event-hyphenation -->
    <child-emitting-camel-case-event @customEvent="handleEvent" />
    <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
    <span v-if="received" data-testid="received">{{ payload }}</span>
  </div>
</template>
