/* eslint-disable space-before-function-paren, comma-dangle, no-param-reassign, camelcase, max-len, no-unused-vars */

import Vue from 'vue';

export default class BoardService {
  constructor ({ boardsEndpoint, listsEndpoint, bulkUpdatePath, boardId }) {
    this.boards = Vue.resource(`${boardsEndpoint}{/id}.json`, {}, {
      issues: {
        method: 'GET',
        url: `${gon.relative_url_root}/-/boards/${boardId}/issues.json`,
      }
    });
    this.lists = Vue.resource(`${listsEndpoint}{/id}`, {}, {
      generate: {
        method: 'POST',
        url: `${listsEndpoint}/generate.json`
      }
    });
    this.issue = Vue.resource(`${gon.relative_url_root}/-/boards/${boardId}/issues{/id}`, {});
    this.issues = Vue.resource(`${listsEndpoint}{/id}/issues`, {}, {
      bulkUpdate: {
        method: 'POST',
        url: bulkUpdatePath,
      },
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
    const data = { id };
    Object.keys(filter).forEach((key) => { data[key] = filter[key]; });

    return this.issues.get(data);
  }

  moveIssue (id, from_list_id = null, to_list_id = null, move_before_id = null, move_after_id = null) {
    return this.issue.update({ id }, {
      from_list_id,
      to_list_id,
      move_before_id,
      move_after_id,
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

  static getIssueInfo(endpoint) {
    return Vue.http.get(endpoint);
  }

  static toggleIssueSubscription(endpoint) {
    return Vue.http.post(endpoint);
  }
}

window.BoardService = BoardService;
