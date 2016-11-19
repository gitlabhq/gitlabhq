/* globals Vue */
/* eslint-disable no-unused-vars, no-param-reassign */
class EnvironmentsService {

  constructor(root) {
    Vue.http.options.root = root;

    this.environments = Vue.resource(root);

    Vue.http.interceptors.push((request, next) => {
      // needed in order to not break the tests.
      if ($.rails) {
        request.headers['X-CSRF-Token'] = $.rails.csrfToken();
      }
      next();
    });
  }

  all() {
    return this.environments.get();
  }
}
