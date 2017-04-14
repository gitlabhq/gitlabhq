import Vue from 'vue';
import issuableTimeTracking from './components/time_tracking/issuable_time_tracking';

import eventHub from './event_hub';
import IssuableService from './services/issuable_service';

const service = new IssuableService(gl.IssuableEndpoint);

eventHub.$on('fetchIssuable', () => {
  service.get().then((response) => {
    eventHub.$emit('receivedIssuable', response.data);
  });
});

document.addEventListener('DOMContentLoaded', () => new Vue(issuableTimeTracking));
