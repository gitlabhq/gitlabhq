import Service from './services/sidebar_service';
import store from './stores/sidebar_store';

export default {
  init(options) {
    store.init(options);
    this.service = new Service(options.endpoint);
  },
  assignYourself(field) {
    store.addUserId(store.currentUserId);
  },
  saveSelectedUsers(field) {
    return new Promise((resolve, reject) => {
      const selected = store.selectedUserIds;

      // If there are no ids, that means we have to unassign (which is id = 0)
      // And it only accepts an array, hence [0]
      this.service.update(field, selected.length === 0 ? [0] : selected)
        .then((response) => {
          store.processUserData(response.data);
          resolve();
        })
        .catch(() => {
          reject();
          return new Flash('Error occurred when saving users');
        });
    });
  },
  fetch() {
    return new Promise((resolve, reject) => {
      this.service.get()
        .then((response) => {
          this.fetching = false;
          store.processUserData(response.data);
          store.processTimeTrackingData(response.data);
          return resolve();
        })
        .catch(() => {
          reject();
          return new Flash('Error occured when fetching sidebar data');
        });
    });
  },
}
