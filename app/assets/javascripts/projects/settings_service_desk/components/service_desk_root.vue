<script>
/* global Flash */

import serviceDeskSetting from './service_desk_setting.vue';
import ServiceDeskStore from '../stores/service_desk_store';
import ServiceDeskService from '../services/service_desk_service';
import eventHub from '../event_hub';

export default {
  name: 'ServiceDeskRoot',

  props: {
    initialIsEnabled: {
      type: Boolean,
      required: true,
    },
    endpoint: {
      type: String,
      required: true,
    },
    incomingEmail: {
      type: String,
      required: false,
      default: '',
    },
  },

  data() {
    const store = new ServiceDeskStore({
      incomingEmail: this.incomingEmail,
    });

    return {
      store,
      state: store.state,
      isEnabled: this.initialIsEnabled,
    };
  },

  components: {
    serviceDeskSetting,
  },

  methods: {
    fetchIncomingEmail() {
      if (this.flash) {
        this.flash.destroy();
      }

      this.service.fetchIncomingEmail()
        .then(res => res.json())
        .then((data) => {
          const email = data.service_desk_address;
          if (!email) {
            throw new Error('Response didn\'t include `service_desk_address`');
          }

          this.store.setIncomingEmail(email);
        })
        .catch(() => {
          this.flash = new Flash('An error occurred while fetching the Service Desk address.', 'alert', this.$el);
        });
    },

    onEnableToggled(isChecked) {
      this.isEnabled = isChecked;
      this.store.resetIncomingEmail();
      if (this.flash) {
        this.flash.destroy();
      }

      this.service.toggleServiceDesk(isChecked)
        .then(res => res.json())
        .then((data) => {
          const email = data.service_desk_address;
          if (isChecked && !email) {
            throw new Error('Response didn\'t include `service_desk_address`');
          }

          this.store.setIncomingEmail(email);
        })
        .catch(() => {
          const verb = isChecked ? 'enabling' : 'disabling';
          this.flash = new Flash(`An error occurred while ${verb} Service Desk.`, 'alert', this.$el);
        });
    },
  },

  created() {
    eventHub.$on('serviceDeskEnabledCheckboxToggled', this.onEnableToggled);

    this.service = new ServiceDeskService(this.endpoint);

    if (this.isEnabled && !this.store.state.incomingEmail) {
      this.fetchIncomingEmail();
    }
  },

  beforeDestroy() {
    eventHub.$off('serviceDeskEnabledCheckboxToggled', this.onEnableToggled);
  },
};
</script>

<template>
  <div>
    <div class="flash-container"></div>
    <service-desk-setting
      :is-enabled="isEnabled"
      :incoming-email="state.incomingEmail" />
  </div>
</template>
