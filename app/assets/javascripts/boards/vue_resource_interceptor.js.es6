Vue.http.interceptors.push((request, next)  => {
  Vue.activeResources = Vue.activeResources ? Vue.activeResources + 1 : 1;

  setTimeout(() => {
    Vue.activeResources--;
  }, 500);
  next();
});
