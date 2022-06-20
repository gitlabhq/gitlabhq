import { getUsers, getUser, getUserStatus } from '~/rest_api';
import Cache from './cache';

class UsersCache extends Cache {
  retrieve(username) {
    if (this.hasData(username)) {
      return Promise.resolve(this.get(username));
    }

    return getUsers('', { username }).then(({ data }) => {
      if (!data.length) {
        throw new Error(`User "${username}" could not be found!`);
      }

      if (data.length > 1) {
        throw new Error(`Expected username "${username}" to be unique!`);
      }

      const user = data[0];
      this.internalStorage[username] = user;
      return user;
    });
    // missing catch is intentional, error handling depends on use case
  }

  retrieveById(userId) {
    if (this.hasData(userId) && this.get(userId).username) {
      return Promise.resolve(this.get(userId));
    }

    return getUser(userId).then(({ data }) => {
      this.internalStorage[userId] = {
        ...this.get(userId),
        ...data,
      };
      return this.internalStorage[userId];
    });
    // missing catch is intentional, error handling depends on use case
  }

  updateById(userId, data) {
    if (!this.hasData(userId)) {
      return;
    }

    this.internalStorage[userId] = {
      ...this.internalStorage[userId],
      ...data,
    };
  }

  retrieveStatusById(userId) {
    if (this.hasData(userId) && this.get(userId).status) {
      return Promise.resolve(this.get(userId).status);
    }

    return getUserStatus(userId).then(({ data }) => {
      if (!this.hasData(userId)) {
        this.internalStorage[userId] = {};
      }
      this.internalStorage[userId].status = data;

      return data;
    });
    // missing catch is intentional, error handling depends on use case
  }
}

export default new UsersCache();
