<script>
import Store from '../../stores/sidebar_store';
import Mediator from '../../sidebar_mediator';
import eventHub from '../../event_hub';
import Flash from '../../../flash';
import { __ } from '../../../locale';
import subscriptions from './subscriptions.vue';

export default {
  data() {
    return {
      mediator: new Mediator(),
      store: new Store(),
    };
  },

  components: {
    subscriptions,
  },

  methods: {
    onToggleSubscription() {
      this.mediator.toggleSubscription()
        .catch(() => {
          Flash(__('Error occurred when toggling the notification subscription'));
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
      :loading="store.isFetching.subscriptions"
      :subscribed="store.subscribed" />
  </div>
</template>
