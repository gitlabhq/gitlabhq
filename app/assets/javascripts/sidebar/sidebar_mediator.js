/* global Flash */

import Service from './services/sidebar_service';
import Store from './stores/sidebar_store';

export default class SidebarMediator {
  constructor(options) {
    if (!SidebarMediator.singleton) {
      this.store = new Store(options);
      this.service = new Service(options.endpoint);
      SidebarMediator.singleton = this;
    }

    return SidebarMediator.singleton;
  }

  assignYourself() {
    this.store.addAssignee(this.store.currentUser);
  }

  saveAssignees(field) {
    const selected = this.store.assignees.map(u => u.id);

    // If there are no ids, that means we have to unassign (which is id = 0)
    // And it only accepts an array, hence [0]
    return this.service.update(field, selected.length === 0 ? [0] : selected);
  }

  fetch() {
    this.service.get()
      .then(response => response.json())
      .then((data) => {
        this.store.setAssigneeData(data);
        this.store.setTimeTrackingData(data);
      })
      .catch(() => new Flash('Error occured when fetching sidebar data'));
  }
}
