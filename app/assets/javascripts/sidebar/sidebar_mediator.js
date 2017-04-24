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
    this.store.addUserId(this.store.currentUserId);
  }

  saveSelectedUsers(field) {
    return new Promise((resolve, reject) => {
      const selected = this.store.selectedUserIds;

      // If there are no ids, that means we have to unassign (which is id = 0)
      // And it only accepts an array, hence [0]
      this.service.update(field, selected.length === 0 ? [0] : selected)
        .then((response) => {
          const data = response.json();
          this.store.processUserData(data);
          resolve();
        })
        .catch(() => {
          reject();
          return new Flash('Error occurred when saving users');
        });
    });
  }

  fetch() {
    return new Promise((resolve, reject) => {
      this.service.get()
        .then((response) => {
          const data = response.json();
          this.store.processUserData(data);
          this.store.processTimeTrackingData(data);
          return resolve();
        })
        .catch(() => {
          reject();
          return new Flash('Error occured when fetching sidebar data');
        });
    });
  }
}
