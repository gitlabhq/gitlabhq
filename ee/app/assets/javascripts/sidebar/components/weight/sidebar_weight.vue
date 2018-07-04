<script>
import Flash from '~/flash';
import eventHub from '~/sidebar/event_hub';
import weightComponent from './weight.vue';

export default {
  components: {
    weight: weightComponent,
  },
  props: {
    mediator: {
      required: true,
      type: Object,
      validator(mediatorObject) {
        return mediatorObject.updateWeight && mediatorObject.store;
      },
    },
  },

  created() {
    eventHub.$on('updateWeight', this.onUpdateWeight);
  },

  beforeDestroy() {
    eventHub.$off('updateWeight', this.onUpdateWeight);
  },

  methods: {
    onUpdateWeight(newWeight) {
      this.mediator.updateWeight(newWeight).catch(() => {
        Flash('Error occurred while updating the issue weight');
      });
    },
  },
};
</script>

<template>
  <weight
    :fetching="mediator.store.isFetching.weight"
    :loading="mediator.store.isLoading.weight"
    :weight="mediator.store.weight"
    :weight-none-value="mediator.store.weightNoneValue"
    :editable="mediator.store.editable"
  />
</template>
