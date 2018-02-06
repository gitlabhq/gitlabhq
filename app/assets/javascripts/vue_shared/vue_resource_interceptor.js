import Vue from 'vue';
import VueResource from 'vue-resource';
import csrf from '../lib/utils/csrf';

Vue.use(VueResource);

// Maintain a global counter for active requests
// see: spec/support/wait_for_requests.rb
Vue.http.interceptors.push((request, next) => {
  window.activeVueResources = window.activeVueResources || 0;
  window.activeVueResources += 1;

  next(() => {
    window.activeVueResources -= 1;
  });
});

// Inject CSRF token and parse headers.
// New Vue Resource version uses Headers, we are expecting a plain object to render pagination
// and polling.
Vue.http.interceptors.push((request, next) => {
  request.headers.set(csrf.headerKey, csrf.token);

  next((response) => {
    // Headers object has a `forEach` property that iterates through all values.
    const headers = {};

    response.headers.forEach((value, key) => {
      headers[key] = value;
    });
    // eslint-disable-next-line no-param-reassign
    response.headers = headers;
  });
});
