import Api from '../../api';
import Cache from './cache';

class UsersCache extends Cache {
  retrieve(username) {
    if (this.hasData(username)) {
      return Promise.resolve(this.get(username));
    }

    return Api.users('', { username })
      .then((users) => {
        if (!users.length) {
          throw new Error(`User "${username}" could not be found!`);
        }

        if (users.length > 1) {
          throw new Error(`Expected username "${username}" to be unique!`);
        }

        const user = users[0];
        this.internalStorage[username] = user;
        return user;
      });
      // missing catch is intentional, error handling depends on use case
  }
}

export default new UsersCache();
