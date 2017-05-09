/* eslint-disable space-before-function-paren, no-underscore-dangle, class-methods-use-this, consistent-return, no-shadow, no-param-reassign, max-len, no-unused-vars */
/* global ListIssue */
/* global ListLabel */
/* global Flash */
import queryData from '../utils/query_data';

const PER_PAGE = 20;

class List {
  constructor (obj, defaultAvatar) {
    this.id = obj.id;
    this._uid = this.guid();
    this.position = obj.position;
    this.title = obj.title;
    this.type = obj.list_type;
    this.preset = ['closed', 'blank'].indexOf(this.type) > -1;
    this.page = 1;
    this.loading = true;
    this.loadingMore = false;
    this.issues = [];
    this.issuesSize = 0;
    this.defaultAvatar = defaultAvatar;

    if (obj.label) {
      this.label = new ListLabel(obj.label);
    }

    if (this.type !== 'blank' && this.id) {
      this.getIssues();
    }
  }

  guid() {
    const s4 = () => Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
    return `${s4()}${s4()}-${s4()}-${s4()}-${s4()}-${s4()}${s4()}${s4()}`;
  }

  save () {
    return gl.boardService.createList(this.label.id)
      .then((resp) => {
        const data = resp.json();

        this.id = data.id;
        this.type = data.list_type;
        this.position = data.position;

        return this.getIssues();
      })
      .catch(() => new Flash('An unexpected error has occurred.', 'alert'));
  }

  destroy () {
    const index = gl.issueBoards.BoardsStore.state.lists.indexOf(this);
    gl.issueBoards.BoardsStore.state.lists.splice(index, 1);
    gl.issueBoards.BoardsStore.updateNewListDropdown(this.id);

    gl.boardService.destroyList(this.id)
      .catch(() => new Flash('An unexpected error has occurred.', 'alert'));
  }

  update () {
    gl.boardService.updateList(this.id, this.position)
      .catch(() => new Flash('An unexpected error has occurred.', 'alert'));
  }

  nextPage () {
    if (this.issuesSize > this.issues.length) {
      if (this.issues.length / PER_PAGE >= 1) {
        this.page += 1;
      }

      return this.getIssues(false);
    }
  }

  getIssues (emptyIssues = true) {
    const data = queryData(gl.issueBoards.BoardsStore.filter.path, { page: this.page });

    if (this.label && data.label_name) {
      data.label_name = data.label_name.filter(label => label !== this.label.title);
    }

    if (emptyIssues) {
      this.loading = true;
    }

    return gl.boardService.getIssuesForList(this.id, data)
      .then((resp) => {
        const data = resp.json();
        this.loading = false;
        this.issuesSize = data.size;

        if (emptyIssues) {
          this.issues = [];
        }

        this.createIssues(data.issues);
      })
      .catch(() => new Flash('Failed to load issues, please try again.', 'alert'));
  }

  newIssue (issue) {
    this.addIssue(issue);
    this.issuesSize += 1;

    return gl.boardService.newIssue(this.id, issue)
      .then((resp) => {
        const data = resp.json();
        issue.id = data.iid;
        issue.milestone = data.milestone;
      })
      .catch(() => new Flash('An unexpected error has occurred.', 'alert'));
  }

  createIssues (data) {
    data.forEach((issueObj) => {
      this.addIssue(new ListIssue(issueObj, this.defaultAvatar));
    });
  }

  addIssue (issue, listFrom, newIndex) {
    let moveBeforeIid = null;
    let moveAfterIid = null;

    if (!this.findIssue(issue.id)) {
      if (newIndex !== undefined) {
        this.issues.splice(newIndex, 0, issue);

        if (this.issues[newIndex - 1]) {
          moveBeforeIid = this.issues[newIndex - 1].id;
        }

        if (this.issues[newIndex + 1]) {
          moveAfterIid = this.issues[newIndex + 1].id;
        }
      } else {
        this.issues.push(issue);
      }

      if (this.label) {
        issue.addLabel(this.label);
      }

      if (listFrom) {
        this.issuesSize += 1;

        this.updateIssueLabel(issue, listFrom, moveBeforeIid, moveAfterIid);
      }
    }
  }

  moveIssue (issue, oldIndex, newIndex, moveBeforeIid, moveAfterIid) {
    this.issues.splice(oldIndex, 1);
    this.issues.splice(newIndex, 0, issue);

    gl.boardService.moveIssue(issue.id, null, null, moveBeforeIid, moveAfterIid)
      .catch(() => new Flash('An unexpected error has occurred.', 'alert'));
  }

  updateIssueLabel(issue, listFrom, moveBeforeIid, moveAfterIid) {
    gl.boardService.moveIssue(issue.id, listFrom.id, this.id, moveBeforeIid, moveAfterIid)
      .catch(() => new Flash('An unexpected error has occurred.', 'alert'));
  }

  findIssue (id) {
    return this.issues.filter(issue => issue.id === id)[0];
  }

  removeIssue (removeIssue) {
    this.issues = this.issues.filter((issue) => {
      const matchesRemove = removeIssue.id === issue.id;

      if (matchesRemove) {
        this.issuesSize -= 1;
        issue.removeLabel(this.label);
      }

      return !matchesRemove;
    });
  }
}

window.List = List;
