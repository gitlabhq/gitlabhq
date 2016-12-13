//= require ../services/approvals_api

(() => {
  let singleton;

  class ApprovalsStore {
    constructor(rootStore) {
      if (!singleton) {
        singleton = gl.ApprovalsStore = this;
        this.init(rootStore);
      }
      return singleton;
    }

    init(rootStore) {
      this.rootStore = rootStore;
      this.api = new gl.ApprovalsApi(rootStore.dataset.endpoint);
    }

    assignToRootStore(data) {
      return this.rootStore.assignToData('approvals', data);
    }

    fetch() {
      return this.api.fetchApprovals()
        .then((res) => this.assignToRootStore(res.data));
    }

    approve() {
      return this.api.approveMergeRequest()
        .then((data) => this.rootStore.assignToData(data));
    }

    unapprove() {
      return this.api.unapproveMergeRequest()
        .then((data) => this.rootStore.assignToData(data));
    }
  }

  gl.ApprovalsStore = ApprovalsStore;
})();


/*
 *2
approvals_required
:
3
approved_by
:
Array[1]
0
:
Object
length
:
1
__proto__
:
Array[0]
created_at
:
"2016-10-17T17:26:13.169Z"
description
:
"Quod corporis labore maiores voluptates ad nobis rem earum. Fugit aperiam officiis temporibus nemo qui consequatur. Perspiciatis maiores expedita est omnis vitae et assumenda."
id
:
7
iid
:
7
merge_status
:
"can_be_merged"
project_id
:
8
state
:
"reopened"
title
:
"Autem ea aut rem rerum sed et eligendi vel doloribus perferendis."
updated_at
:
"2016-12-08T17:20:40.530Z"
user_can_approve
:
false
user_has_approved
:
true
 *
 *
 * */
