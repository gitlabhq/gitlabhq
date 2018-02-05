import Api from '../../api';
import Cache from './cache';

class UsersCache extends Cache {
  retrieve(username) {
    if (this.hasData(username)) {
      return Promise.resolve(this.get(username));
    }

    return Api.users('', { username })
      .then(({ data }) => {
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
}

export default new UsersCache();
