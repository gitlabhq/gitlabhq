<script>
import PipelineNotificationClient from '../../service_workers/clients/pipeline_notification_client';
import axios from '../../lib/utils/axios_utils';

export default {
  props: {
    pipelineId: {
      type: Number,
      required: true,
    },

    isSubscribed: {
      type: Boolean,
      required: false,
      default: false,
    },
  },

  data() {
    return {
      hasPermission: true,
    };
  },

  computed: {
    actionName() {
      return this.isSubscribed ? 'Unsubscribe' : 'Subscribe';
    },
  },

  methods: {
    subscribe() {
      PipelineNotificationClient.init()
        .then(() => PipelineNotificationClient.getSubscription())
        .then((subscription) => {
          if (!subscription) return PipelineNotificationClient.subscribe();

          return subscription;
        })
        .then((subscription) => {
          const subscriptionData = subscription.toJSON();

          // lazy
          return axios.put('/profile.json', {
            user: {
              webpush_endpoint: subscriptionData.endpoint,
              webpush_p256dh: subscriptionData.keys.p256dh,
              webpush_auth: subscriptionData.keys.auth,
              subscribed_pipeline: this.pipelineId,
            },
          });
        })
        .then(() => {
          this.$emit('setIsSubscribed', true);
          this.hasPermission = true;
        })
        .catch(() => {
          this.hasPermission = false;
        });
    },
  },
};
</script>


<template>
<button
  :disabled="!hasPermission"
  class="btn"
  type="button"
  @click="subscribe"
>
  {{ actionName }} to push notifications
</button>
</template>
