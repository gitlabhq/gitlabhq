/* eslint-disable no-param-reassign, no-plusplus */
import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

Vue.http.interceptors.push((request, next) => {
  Vue.activeResources = Vue.activeResources ? Vue.activeResources + 1 : 1;

  next(() => {
    Vue.activeResources--;
  });
});

Vue.http.interceptors.push((request, next) => {
  // needed in order to not break the tests.
  if ($.rails) {
    request.headers['X-CSRF-Token'] = $.rails.csrfToken();
  }
  next();
});
