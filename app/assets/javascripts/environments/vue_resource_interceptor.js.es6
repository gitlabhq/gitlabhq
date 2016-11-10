/* eslint-disable */
Vue.http.interceptors.push((request, next) => {
  Vue.activeResources = Vue.activeResources ? Vue.activeResources + 1 : 1;

  next(function (response) {
    console.log("this is the repsponse", JSON.stringify(response, null, '  '));
    if (typeof response.data === "string") {
      response.data = JSON.parse(response.data)
    }
    
    Vue.activeResources--;
  });
});
