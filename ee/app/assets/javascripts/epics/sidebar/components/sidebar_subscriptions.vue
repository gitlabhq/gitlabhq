<script>
  import Subscriptions from '~/sidebar/components/subscriptions/subscriptions.vue';

  export default {
    components: {
      Subscriptions,
    },
    props: {
      loading: {
        type: Boolean,
        required: true,
      },
      subscribed: {
        type: Boolean,
        required: true,
      },
    },
    methods: {
      onToggleSubscription() {
        this.$emit('toggleSubscription');
      },
    },
  };
</script>

<template>
  <div class="block subscriptions">
    <subscriptions
      :loading="loading"
      :subscribed="subscribed"
      @toggleSubscription="onToggleSubscription"
    />
  </div>
</template>
