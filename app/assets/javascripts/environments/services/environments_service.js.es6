class EnvironmentsService {
  
  constructor (root) {
    Vue.http.options.root = root;
    
    debugger;
    
    this.environments = Vue.resource(root);
    
    Vue.http.interceptors.push((request, next) => {
      request.headers['X-CSRF-Token'] = $.rails.csrfToken();
      next();
    });
  }
  
  all () {
    return this.environments.get();
  }
};