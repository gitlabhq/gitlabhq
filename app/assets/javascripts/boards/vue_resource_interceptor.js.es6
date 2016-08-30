Vue.http.interceptors.push((request, next)  => {
  Vue.activeResources = Vue.activeResources ? Vue.activeResources + 1 : 1;

  Vue.nextTick(() => {
    setTimeout(() => {
      Vue.activeResources--;
    }, 500);
  });
  next();
});
