/* eslint-disable */
Vue.http.interceptors.push((request, next) => {
  Vue.activeResources = Vue.activeResources ? Vue.activeResources + 1 : 1;

  next(function (response) {
    if (typeof response.data === "string") {
      response.data = JSON.parse(response.data)
    }

    Vue.activeResources--;
  });
});
