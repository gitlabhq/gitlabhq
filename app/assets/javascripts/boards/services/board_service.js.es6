class BoardService {
  constructor (root) {
    Vue.http.options.root = root;

    this.resource = Vue.resource(`${root}{/id}`, {}, {
      all: {
        method: 'GET',
        url: 'all'
      }
    });
  }

  setCSRF () {
    Vue.http.headers.common['X-CSRF-Token'] = $.rails.csrfToken();
  }

  all () {
    this.setCSRF();
    return this.resource.all();
  }

  updateBoard (id, index) {
    this.setCSRF();
    return this.resource.update({ id: id }, { index: index });
  }
};
