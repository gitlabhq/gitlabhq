class BoardService {
  constructor (root) {
    Vue.http.options.root = root;

    this.lists = Vue.resource(`${root}{/id}.json`, {});
    this.list = Vue.resource(`${root}/lists{/id}.json`, {});
    this.issue = Vue.resource(`${root}/issues{/id}.json`, {});
    this.issues = Vue.resource(`${root}/lists{/id}/issues.json`, {});
  }

  setCSRF () {
    Vue.http.headers.common['X-CSRF-Token'] = $.rails.csrfToken();
  }

  all () {
    this.setCSRF();
    return this.lists.get();
  }

  createList (labelId) {
    this.setCSRF();

    return this.list.save({}, {
      list: {
        label_id: labelId
      }
    });
  }

  updateList (list) {
    this.setCSRF();

    return this.list.update({ id: list.id }, {
      list: {
        position: list.position
      }
    });
  }

  destroyList (id) {
    this.setCSRF();

    return this.list.delete({ id });
  }

  getIssuesForList (id, filter = {}) {
    const data = _.extend({ id }, filter)
    this.setCSRF();

    return this.issues.get(data);
  }

  moveIssue (id, from, to) {
    return this.issue.update({ id }, {
      issue: {
        from,
        to
      }
    });
  }
};
