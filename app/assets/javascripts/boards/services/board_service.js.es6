class BoardService {
  constructor (root) {
    Vue.http.options.root = root;

    this.lists = Vue.resource(`${root}/lists{/id}.json`, {}, {
      generate: {
        method: 'POST',
        url: `${root}/lists/generate.json`
      }
    });
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

  generateDefaultLists () {
    this.setCSRF();

    return this.lists.generate({});
  }

  createList (labelId) {
    this.setCSRF();

    return this.lists.save({}, {
      list: {
        label_id: labelId
      }
    });
  }

  updateList (list) {
    this.setCSRF();

    return this.lists.update({ id: list.id }, {
      list: {
        position: list.position
      }
    });
  }

  destroyList (id) {
    this.setCSRF();

    return this.lists.delete({ id });
  }

  getIssuesForList (id, filter = {}) {
    let data = { id };
    Object.keys(filter).forEach((key) => { data[key] = filter[key]; });
    this.setCSRF();

    return this.issues.get(data);
  }

  moveIssue (id, from_list_id, to_list_id) {
    return this.issue.update({ id }, {
      from_list_id,
      to_list_id
    });
  }
};
