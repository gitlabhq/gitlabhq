<script>
import MessagesTableRow from './messages_table_row.vue';

export default {
  name: 'MessagesTable',
  components: {
    MessagesTableRow,
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
    <messages-table-row v-for="message in messages" :key="message.id" :message="message" />
  </div>
</template>
