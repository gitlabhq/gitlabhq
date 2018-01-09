<script>
  /* eslint-disable vue/require-default-prop */
  import { __ } from '../../../locale';
  import eventHub from '../../event_hub';
  import loadingButton from '../../../vue_shared/components/loading_button.vue';

  export default {
    components: {
      loadingButton,
    },
    props: {
      loading: {
        type: Boolean,
        required: false,
        default: false,
      },
      subscribed: {
        type: Boolean,
        required: false,
      },
      id: {
        type: Number,
        required: false,
      },
    },
    computed: {
      buttonLabel() {
        let label;
        if (this.subscribed === false) {
          label = __('Subscribe');
        } else if (this.subscribed === true) {
          label = __('Unsubscribe');
        }

        return label;
      },
    },
    methods: {
      toggleSubscription() {
        eventHub.$emit('toggleSubscription', this.id);
      },
    },
  };
</script>

<template>
  <div>
    <div class="sidebar-collapsed-icon">
      <i
        class="fa fa-rss"
        aria-hidden="true"
      >
      </i>
    </div>
    <span class="issuable-header-text hide-collapsed pull-left">
      {{ __('Notifications') }}
    </span>
    <loading-button
      ref="loadingButton"
      class="btn btn-default pull-right hide-collapsed js-issuable-subscribe-button"
      :loading="loading"
      :label="buttonLabel"
      @click="toggleSubscription"
    />
  </div>
</template>
