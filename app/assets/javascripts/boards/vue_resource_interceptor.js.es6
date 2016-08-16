Vue.activeResources = 0;

Vue.http.interceptors.push((request, next)  => {
  Vue.activeResources++;

  next((response) => {
    Vue.activeResources--;
  });
});
