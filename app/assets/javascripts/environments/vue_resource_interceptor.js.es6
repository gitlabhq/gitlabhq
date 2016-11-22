/* global Vue */
Vue.http.interceptors.push((request, next) => {
  Vue.activeResources = Vue.activeResources ? Vue.activeResources + 1 : 1;

  next((response) => {
    if (typeof response.data === 'string') {
      response.data = JSON.parse(response.data); // eslint-disable-line
    }

    Vue.activeResources--; // eslint-disable-line
  });
});
