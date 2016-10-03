class BoardService {
  constructor (root) {
    Vue.http.options.root = root;

    this.lists = Vue.resource(`${root}/lists{/id}`, {}, {
      generate: {
        method: 'POST',
        url: `${root}/lists/generate.json`
      }
    });
    this.issue = Vue.resource(`${root}/issues{/id}`, {});
    this.issues = Vue.resource(`${root}/lists{/id}/issues`, {});

    Vue.http.interceptors.push((request, next) => {
      request.headers['X-CSRF-Token'] = $.rails.csrfToken();
      next();
    });
  }

  all () {
    return this.lists.get();
  }

  generateDefaultLists () {
    return this.lists.generate({});
  }

  createList (label_id) {
    return this.lists.save({}, {
      list: {
        label_id
      }
    });
  }

  updateList (id, position) {
    return this.lists.update({ id }, {
      list: {
        position
      }
    });
  }

  destroyList (id) {
    return this.lists.delete({ id });
  }

  getIssuesForList (id, filter = {}) {
    let data = { id };
    Object.keys(filter).forEach((key) => { data[key] = filter[key]; });

    return this.issues.get(data);
  }

  moveIssue (id, from_list_id, to_list_id) {
    return this.issue.update({ id }, {
      from_list_id,
      to_list_id
    });
  }

  newIssue (id, issue) {
    return this.issues.save({ id }, {
      issue: {
        title: issue.title
      }
    });
  }
};
