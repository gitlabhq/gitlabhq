/* eslint-disable */
class List {
  constructor (obj) {
    this.id = obj.id;
    this._uid = this.guid();
    this.title = obj.title;
    this.type = obj.list_type;
    this.preset = ['backlog', 'done', 'blank'].indexOf(this.type) > -1;
    this.filters = gl.issueBoards.BoardsStore.state.filters;
    this.page = 1;
    this.loading = true;
    this.loadingMore = false;
    this.issues = [];
    this.issuesSize = 0;
    this._interval = new gl.SmartInterval({
      callback: () => {
        this.getIssues(false);
      },
      startingInterval: 6 * 1000, // 6 seconds
      maxInterval: 11 * 1000, // 11 seconds
      incrementByFactorOf: 10,
      lazyStart: true,
    });

    if (this.type === 'done') {
      this.position = Infinity;
    } else if (this.type === 'backlog') {
      this.position = -1;
    } else {
      this.position = obj.position;
    }

    if (obj.label) {
      this.label = new ListLabel(obj.label);
    }

    if (this.type !== 'blank' && this.id) {
      this.getIssues()
        .then(() => {
          this._interval.start();
        });
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
      });
  }

  destroy (persist = true) {
    const index = gl.issueBoards.BoardsStore.state.lists.indexOf(this);
    gl.issueBoards.BoardsStore.state.lists.splice(index, 1);
    gl.issueBoards.BoardsStore.updateNewListDropdown(this.id);

    this._interval.destroy();

    if (persist) {
      gl.boardService.destroyList(this.id);
    }
  }

  update () {
    gl.boardService.updateList(this.id, this.position);
  }

  nextPage () {
    if (this.issuesSize > this.issues.length) {
      this.page++;

      return this.getIssues(false);
    }
  }

  getIssues (emptyIssues = true) {
    const filters = this.filters;
    let data = { page: this.page };

    Object.keys(filters).forEach((key) => { data[key] = filters[key]; });

    if (this.label) {
      data.label_name = data.label_name.filter( label => label !== this.label.title );
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
      });
  }

  newIssue (issue) {
    this.addIssue(issue);
    this.issuesSize++;

    return gl.boardService.newIssue(this.id, issue)
      .then((resp) => {
        const data = resp.json();
        issue.id = data.iid;
      });
  }

  createIssues (data) {
    data.forEach((issueObj) => {
      const issue = this.findIssue(issueObj.iid);

      if (issue) {
        if (issueObj.assignee) {
          issue.assignee = new ListUser(issueObj.assignee);
        } else {
          issue.assignee = undefined;
        }
      } else {
        this.addIssue(new ListIssue(issueObj));
      }
    });
  }

  addIssue (issue, listFrom, newIndex) {
    if (!this.findIssue(issue.id)) {
      if (newIndex !== undefined) {
        this.issues.splice(newIndex, 0, issue);
      } else {
        this.issues.push(issue);
      }

      if (this.label) {
        issue.addLabel(this.label);
      }

      if (listFrom) {
        this.issuesSize++;
        gl.boardService.moveIssue(issue.id, listFrom.id, this.id)
          .then(() => {
            listFrom.getIssues(false);
          });
      }
    }
  }

  findIssue (id) {
    return this.issues.filter( issue => issue.id === id )[0];
  }

  removeIssue (removeIssue) {
    this.issues = this.issues.filter((issue) => {
      const matchesRemove = removeIssue.id === issue.id;

      if (matchesRemove) {
        this.issuesSize--;
        issue.removeLabel(this.label);
      }

      return !matchesRemove;
    });
  }
}
