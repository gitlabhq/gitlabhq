<script>
  import eventHub from '../../event_hub';
  import icon from '../../../vue_shared/components/icon.vue';
  import toggleButton from '../../../vue_shared/components/toggle_button.vue';

  export default {
    components: {
      icon,
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
      notificationIcon() {
        return this.subscribed ? 'notifications' : 'notifications-off';
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
      <icon
        :name="notificationIcon"
        :size="16"
        aria-hidden="true"
        class="sidebar-item-icon is-active"
      />
    </div>
    <span class="issuable-header-text hide-collapsed pull-left">
      {{ __('Notifications') }}
    </span>
    <toggle-button
      ref="toggleButton"
      class="pull-right hide-collapsed js-issuable-subscribe-button"
      :is-loading="showLoadingState"
      :value="subscribed"
      @change="toggleSubscription"
    />
  </div>
</template>
