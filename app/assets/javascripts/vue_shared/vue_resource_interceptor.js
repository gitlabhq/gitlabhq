/* eslint-disable func-names, prefer-arrow-callback, no-unused-vars,
no-param-reassign, no-plusplus */
/* global Vue */

Vue.http.interceptors.push((request, next) => {
  Vue.activeResources = Vue.activeResources ? Vue.activeResources + 1 : 1;

  next((response) => {
    if (typeof response.data === 'string') {
      response.data = JSON.parse(response.data);
    }

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
