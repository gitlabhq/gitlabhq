<script>
import PipelineNotificationClient from '../../service_workers/clients/pipeline_notification_client';
import axios from '../../lib/utils/axios_utils';

export default {
  data() {
    return {
      hasPermission: true,
    };
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
          return axios.put('/profile', {
            user: {
              webpush_endpoint: subscriptionData.endpoint,
              webpush_p256dh: subscriptionData.keys.p256dh,
              webpush_auth: subscriptionData.keys.auth,
              subscribed_pipelines: '68,69',
            },
          });
        })
        .then(() => {
          this.hasPermission = true;
        })
        .catch((error) => {
          console.log(error);
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
  Subscribe to push notifications
</button>
</template>
