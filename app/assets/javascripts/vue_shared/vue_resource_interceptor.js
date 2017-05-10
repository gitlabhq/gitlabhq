import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

// Maintain a global counter for active requests
// see: spec/support/wait_for_vue_resource.rb
Vue.http.interceptors.push((request, next) => {
  window.activeVueResources = window.activeVueResources || 0;
  window.activeVueResources += 1;
  console.log("=== Vue interecepting request: " + JSON.stringify(request));

  next(() => {
    console.log("=== Vue done intercepting request: " + JSON.stringify(request));
    window.activeVueResources -= 1;
  });
});

// Inject CSRF token so we don't break any tests.
Vue.http.interceptors.push((request, next) => {
  if ($.rails) {
    // eslint-disable-next-line no-param-reassign
    request.headers['X-CSRF-Token'] = $.rails.csrfToken();
  }
  next();
});
