<script>
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';

export default {
  name: 'ProjectListItemActionsCE',
  components: {
    ListActions,
  },
  props: {
    project: {
      type: Object,
      required: true,
    },
  },
  computed: {
    actions() {
      return {
        [ACTION_EDIT]: {
          href: this.project.editPath,
        },
        [ACTION_DELETE]: {
          action: this.onActionDelete,
        },
      };
    },
  },
  methods: {
    onActionDelete() {
      this.$emit('delete');
    },
  },
};
</script>

<template>
  <list-actions :actions="actions" :available-actions="project.availableActions" />
</template>
