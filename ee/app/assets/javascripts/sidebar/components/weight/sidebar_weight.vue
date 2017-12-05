<script>
import Flash from '~/flash';
import eventHub from '~/sidebar/event_hub';
import weightComponent from './weight.vue';

export default {
  props: {
    mediator: {
      required: true,
      type: Object,
      validator(mediatorObject) {
        return mediatorObject.updateWeight && mediatorObject.store;
      },
    },
  },

  components: {
    weight: weightComponent,
  },

  methods: {
    onUpdateWeight(newWeight) {
      this.mediator.updateWeight(newWeight)
        .catch(() => {
          Flash('Error occurred while updating the issue weight');
        });
    },
  },

  created() {
    eventHub.$on('updateWeight', this.onUpdateWeight);
  },

  beforeDestroy() {
    eventHub.$off('updateWeight', this.onUpdateWeight);
  },
};
</script>

<template>
  <weight
    :fetching="mediator.store.isFetching.weight"
    :loading="mediator.store.isLoading.weight"
    :weight="mediator.store.weight"
    :weight-options="mediator.store.weightOptions"
    :weight-none-value="mediator.store.weightNoneValue"
    :editable="mediator.store.editable" />
</template>
