/* eslint-disable no-new */
import Vue from 'vue';
import ServiceDeskSetting from './components/service_desk_setting';
import ServiceDeskStore from './stores/service_desk_store';
import ServiceDeskService from './services/service_desk_service';
import eventHub from './event_hub';

class ServiceDeskRoot {
  constructor(wrapperElement) {
    this.wrapperElement = wrapperElement;
    const isEnabled = typeof this.wrapperElement.dataset.enabled !== 'undefined' &&
      this.wrapperElement.dataset.enabled !== 'false';
    const incomingEmail = this.wrapperElement.dataset.incomingEmail;
    const endpoint = this.wrapperElement.dataset.endpoint;

    this.store = new ServiceDeskStore({
      isEnabled,
      incomingEmail,
    });
    this.service = new ServiceDeskService(endpoint);
  }

  init() {
    this.bindEvents();

    if (this.store.state.isEnabled && !this.store.state.incomingEmail) {
      this.fetchIncomingEmail();
    }

    this.render();
  }

  bindEvents() {
    this.onEnableToggledWrapper = this.onEnableToggled.bind(this);

    eventHub.$on('serviceDeskEnabledCheckboxToggled', this.onEnableToggledWrapper);
  }

  unbindEvents() {
    eventHub.$off('serviceDeskEnabledCheckboxToggled', this.onEnableToggledWrapper);
  }

  render() {
    this.vm = new Vue({
      el: this.wrapperElement,
      data: this.store.state,
      template: `
        <service-desk-setting
          :isEnabled="isEnabled"
          :incomingEmail="incomingEmail"
          :fetchError="fetchError" />
      `,
      components: {
        'service-desk-setting': ServiceDeskSetting,
      },
    });
  }

  fetchIncomingEmail() {
    this.service.fetchIncomingEmail()
      .then((incomingEmail) => {
        this.store.setIncomingEmail(incomingEmail);
      })
      .catch((err) => {
        this.store.setFetchError(err);
      });
  }

  onEnableToggled(isChecked) {
    this.store.setIsActivated(isChecked);
    this.store.setIncomingEmail('');
    this.store.setFetchError(null);

    this.service.toggleServiceDesk(isChecked)
      .then((incomingEmail) => {
        this.store.setIncomingEmail(incomingEmail);
      })
      .catch((err) => {
        this.store.setFetchError(err);
      });
  }

  destroy() {
    this.unbindEvents();
    if (this.vm) {
      this.vm.$destroy();
    }
  }
}

export default ServiceDeskRoot;
