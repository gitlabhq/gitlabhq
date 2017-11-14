<script>
import eventHub from '../../event_hub';
import Flash from '../../../flash';
import subscriptions from './subscriptions.vue';

export default {
  props: {
    mediator: {
      required: true,
      type: Object,
      validator(mediatorObject) {
        return mediatorObject.toggleSubscription && mediatorObject.store;
      },
    },
  },

  components: {
    subscriptions,
  },

  methods: {
    onToggleSubscription() {
      this.mediator.toggleSubscription()
        .catch(() => {
          Flash('Error occurred when toggling the notification subscription');
        });
    },
  },

  created() {
    eventHub.$on('toggleSubscription', this.onToggleSubscription);
  },

  beforeDestroy() {
    eventHub.$off('toggleSubscription', this.onToggleSubscription);
  },
};
</script>

<template>
  <div class="block subscriptions">
    <subscriptions
      :loading="mediator.store.isFetching.subscriptions"
      :subscribed="mediator.store.subscribed" />
  </div>
</template>
