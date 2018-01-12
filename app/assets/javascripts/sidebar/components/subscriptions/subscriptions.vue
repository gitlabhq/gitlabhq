<script>
  import eventHub from '../../event_hub';
  import toggleButton from '../../../vue_shared/components/toggle_button.vue';

  export default {
    components: {
      toggleButton,
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
        default: null,
      },
      id: {
        type: Number,
        required: false,
        default: null,
      },
    },
    computed: {
      showLoadingState() {
        return this.subscribed === null || this.loading;
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
        class="fa"
        :class="{
          'fa-bell': subscribed,
          'fa-bell-slash': !subscribed,
        }"
        aria-hidden="true"
      >
      </i>
    </div>
    <span class="issuable-header-text hide-collapsed pull-left">
      {{ __('Notifications') }}
    </span>
    <toggle-button
      ref="loadingButton"
      class="pull-right hide-collapsed js-issuable-subscribe-button"
      :is-loading="showLoadingState"
      :value="subscribed"
      @change="toggleSubscription"
    />
  </div>
</template>
