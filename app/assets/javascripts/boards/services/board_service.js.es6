/* eslint-disable space-before-function-paren, comma-dangle, no-param-reassign, camelcase, max-len, no-unused-vars, no-else-return */
/* global Vue */

class BoardService {
  constructor (root, bulkUpdatePath, boardId) {
    this.boards = Vue.resource(`${root}{/id}.json`, {}, {
      issues: {
        method: 'GET',
        url: `${root}/${boardId}/issues.json`
      }
    });
    this.lists = Vue.resource(`${root}/${boardId}/lists{/id}`, {}, {
      generate: {
        method: 'POST',
        url: `${root}/${boardId}/lists/generate.json`
      }
    });
    this.issue = Vue.resource(`${root}/${boardId}/issues{/id}`, {});
    this.issues = Vue.resource(`${root}/${boardId}/lists{/id}/issues`, {}, {
      bulkUpdate: {
        method: 'POST',
        url: bulkUpdatePath,
      },
    });

    Vue.http.interceptors.push((request, next) => {
      request.headers['X-CSRF-Token'] = $.rails.csrfToken();
      next();
    });
  }

  allBoards () {
    return this.boards.get();
  }

  createBoard (board) {
    if (board.id) {
      return this.boards.update({ id: board.id }, board);
    } else {
      return this.boards.save({}, board);
    }
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
    const data = { id };
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
      issue
    });
  }

  getBacklog(data) {
    return this.boards.issues(data);
  }

  bulkUpdate(issueIds, extraData = {}) {
    const data = {
      update: Object.assign(extraData, {
        issuable_ids: issueIds.join(','),
      }),
    };

    return this.issues.bulkUpdate(data);
  }
}

window.BoardService = BoardService;
