<script>
import MessagesTable from './messages_table.vue';

export default {
  name: 'BroadcastMessagesBase',
  components: {
    MessagesTable,
  },
  props: {
    messages: {
      type: Array,
      required: true,
    },
  },
};
</script>
<template>
  <div>
    <messages-table v-if="messages.length > 0" :messages="messages" />
  </div>
</template>
