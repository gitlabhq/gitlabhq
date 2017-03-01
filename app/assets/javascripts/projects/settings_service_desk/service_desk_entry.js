/* eslint-disable no-new */
import Vue from 'vue';
import ServiceDeskSetting from './components/service_desk_setting';
import ServiceDeskStore from './stores/service_desk_store';
import ServiceDeskService from './services/service_desk_service';
import eventHub from './event_hub';

class ServiceDeskEntry {
  constructor(wrapperElement) {
    this.wrapperElement = wrapperElement;

    this.store = new ServiceDeskStore();
    this.service = new ServiceDeskService('http://apilab.gitlap.com/some-project');
  }

  init() {
    this.bindEvents();
    this.render();
  }

  bindEvents() {
    this.onEnableToggledWrapper = this.onEnableToggled.bind(this);

    eventHub.$on('serviceDeskEnabledCheckboxToggled', this.onEnableToggledWrapper);
  }

  unbindEvents() {
    eventHub.$on('serviceDeskEnabledCheckboxToggled', this.onEnableToggledWrapper);
  }

  render() {
    this.vm = new Vue({
      el: this.wrapperElement,
      data: this.store.state,
      template: `
        <service-desk-setting
          :isActivated="isActivated"
          :incomingEmail="incomingEmail"
          :fetchError="fetchError" />
      `,
      components: {
        'service-desk-setting': ServiceDeskSetting,
      },
    });
  }

  onEnableToggled(isChecked) {
    this.store.setIsActivated(isChecked);
    if (isChecked) {
      this.store.setIncomingEmail('');
      this.store.setFetchError(null);
      this.service.fetchIncomingEmail()
        .then((incomingEmail) => {
          this.store.setIncomingEmail(incomingEmail);
        })
        .catch((err) => {
          this.store.setFetchError(err);
        });
    }
  }

  destroy() {
    this.unbindEvents();
    if (this.vm) {
      this.vm.$destroy();
    }
  }
}

export default ServiceDeskEntry;
