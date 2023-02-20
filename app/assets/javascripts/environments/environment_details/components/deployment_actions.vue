<script>
import ActionsComponent from '~/environments/components/environment_actions.vue';

export default {
  components: {
    ActionsComponent,
  },
  props: {
    actions: {
      // actions shape:
      /* Array<{
           playable: boolean,
           playPath: url,
           name: string
           scheduledAt: ISO_timestamp | null
      }>
      */
      type: Array,
      required: true,
    },
  },
  computed: {
    isActionsShown() {
      return this.actions.length > 0;
    },
  },
};
</script>
<template>
  <actions-component v-if="isActionsShown" :actions="actions" graphql />
</template>
