import * as UserApi from '~/api/user_api';
import UsersCache from '~/lib/utils/users_cache';

describe('UsersCache', () => {
  const dummyUsername = 'win';
  const dummyUserId = 123;
  const dummyUser = {
    name: 'has a farm',
    username: 'farmer',
  };
  const dummyUserStatus = 'my status';

  beforeEach(() => {
    UsersCache.internalStorage = {};
  });

  describe('get', () => {
    it('returns undefined for empty cache', () => {
      expect(UsersCache.internalStorage).toEqual({});

      const user = UsersCache.get(dummyUsername);

      expect(user).toBe(undefined);
    });

    it('returns undefined for missing user', () => {
      UsersCache.internalStorage['no body'] = 'no data';

      const user = UsersCache.get(dummyUsername);

      expect(user).toBe(undefined);
    });

    it('returns matching user', () => {
      UsersCache.internalStorage[dummyUsername] = dummyUser;

      const user = UsersCache.get(dummyUsername);

      expect(user).toBe(dummyUser);
    });
  });

  describe('hasData', () => {
    it('returns false for empty cache', () => {
      expect(UsersCache.internalStorage).toEqual({});

      expect(UsersCache.hasData(dummyUsername)).toBe(false);
    });

    it('returns false for missing user', () => {
      UsersCache.internalStorage['no body'] = 'no data';

      expect(UsersCache.hasData(dummyUsername)).toBe(false);
    });

    it('returns true for matching user', () => {
      UsersCache.internalStorage[dummyUsername] = dummyUser;

      expect(UsersCache.hasData(dummyUsername)).toBe(true);
    });
  });

  describe('remove', () => {
    it('does nothing if cache is empty', () => {
      expect(UsersCache.internalStorage).toEqual({});

      UsersCache.remove(dummyUsername);

      expect(UsersCache.internalStorage).toEqual({});
    });

    it('does nothing if cache contains no matching data', () => {
      UsersCache.internalStorage['no body'] = 'no data';
      UsersCache.remove(dummyUsername);

      expect(UsersCache.internalStorage['no body']).toBe('no data');
    });

    it('removes matching data', () => {
      UsersCache.internalStorage[dummyUsername] = dummyUser;
      UsersCache.remove(dummyUsername);

      expect(UsersCache.internalStorage).toEqual({});
    });
  });

  describe('retrieve', () => {
    let apiSpy;

    beforeEach(() => {
      jest
        .spyOn(UserApi, 'getUsers')
        .mockImplementation((query, options) => apiSpy(query, options));
    });

    it('stores and returns data from API call if cache is empty', async () => {
      apiSpy = (query, options) => {
        expect(query).toBe('');
        expect(options).toEqual({
          username: dummyUsername,
        });

        return Promise.resolve({
          data: [dummyUser],
        });
      };

      const user = await UsersCache.retrieve(dummyUsername);
      expect(user).toBe(dummyUser);
      expect(UsersCache.internalStorage[dummyUsername]).toBe(dummyUser);
    });

    it('returns undefined if Ajax call fails and cache is empty', async () => {
      const dummyError = new Error('server exploded');

      apiSpy = (query, options) => {
        expect(query).toBe('');
        expect(options).toEqual({
          username: dummyUsername,
        });

        return Promise.reject(dummyError);
      };

      await expect(UsersCache.retrieve(dummyUsername)).rejects.toEqual(dummyError);
    });

    it('makes no Ajax call if matching data exists', async () => {
      UsersCache.internalStorage[dummyUsername] = dummyUser;

      apiSpy = () => {
        throw new Error('expected no Ajax call!');
      };

      const user = await UsersCache.retrieve(dummyUsername);
      expect(user).toBe(dummyUser);
    });
  });

  describe('retrieveById', () => {
    let apiSpy;

    beforeEach(() => {
      jest.spyOn(UserApi, 'getUser').mockImplementation((id) => apiSpy(id));
    });

    it('stores and returns data from API call if cache is empty', async () => {
      apiSpy = (id) => {
        expect(id).toBe(dummyUserId);

        return Promise.resolve({
          data: dummyUser,
        });
      };

      const user = await UsersCache.retrieveById(dummyUserId);
      expect(user).toEqual(dummyUser);
      expect(UsersCache.internalStorage[dummyUserId]).toEqual(dummyUser);
    });

    it('returns undefined if Ajax call fails and cache is empty', async () => {
      const dummyError = new Error('server exploded');

      apiSpy = (id) => {
        expect(id).toBe(dummyUserId);

        return Promise.reject(dummyError);
      };

      await expect(UsersCache.retrieveById(dummyUserId)).rejects.toEqual(dummyError);
    });

    it('makes no Ajax call if matching data exists', async () => {
      UsersCache.internalStorage[dummyUserId] = dummyUser;

      apiSpy = () => {
        throw new Error('expected no Ajax call!');
      };

      const user = await UsersCache.retrieveById(dummyUserId);
      expect(user).toBe(dummyUser);
    });

    it('does not clobber existing cached values', async () => {
      UsersCache.internalStorage[dummyUserId] = {
        status: dummyUserStatus,
      };

      apiSpy = (id) => {
        expect(id).toBe(dummyUserId);

        return Promise.resolve({
          data: dummyUser,
        });
      };

      const user = await UsersCache.retrieveById(dummyUserId);
      const expectedUser = {
        status: dummyUserStatus,
        ...dummyUser,
      };

      expect(user).toEqual(expectedUser);
      expect(UsersCache.internalStorage[dummyUserId]).toEqual(expectedUser);
    });
  });

  describe('retrieveStatusById', () => {
    let apiSpy;

    beforeEach(() => {
      jest.spyOn(UserApi, 'getUserStatus').mockImplementation((id) => apiSpy(id));
    });

    it('stores and returns data from API call if cache is empty', async () => {
      apiSpy = (id) => {
        expect(id).toBe(dummyUserId);

        return Promise.resolve({
          data: dummyUserStatus,
        });
      };

      const userStatus = await UsersCache.retrieveStatusById(dummyUserId);
      expect(userStatus).toBe(dummyUserStatus);
      expect(UsersCache.internalStorage[dummyUserId].status).toBe(dummyUserStatus);
    });

    it('returns undefined if Ajax call fails and cache is empty', async () => {
      const dummyError = new Error('server exploded');

      apiSpy = (id) => {
        expect(id).toBe(dummyUserId);

        return Promise.reject(dummyError);
      };

      await expect(UsersCache.retrieveStatusById(dummyUserId)).rejects.toEqual(dummyError);
    });

    it('makes no Ajax call if matching data exists', async () => {
      UsersCache.internalStorage[dummyUserId] = {
        status: dummyUserStatus,
      };

      apiSpy = () => {
        throw new Error('expected no Ajax call!');
      };

      const userStatus = await UsersCache.retrieveStatusById(dummyUserId);
      expect(userStatus).toBe(dummyUserStatus);
    });
  });

  describe('updateById', () => {
    describe('when the user is not cached', () => {
      it('does nothing and returns undefined', () => {
        expect(UsersCache.updateById(dummyUserId, { name: 'root' })).toBe(undefined);
        expect(UsersCache.internalStorage).toStrictEqual({});
      });
    });

    describe('when the user is cached', () => {
      const updatedName = 'has two farms';
      beforeEach(() => {
        UsersCache.internalStorage[dummyUserId] = dummyUser;
      });

      it('updates the user only with the new data', async () => {
        UsersCache.updateById(dummyUserId, { name: updatedName });

        expect(await UsersCache.retrieveById(dummyUserId)).toStrictEqual({
          username: dummyUser.username,
          name: updatedName,
        });
      });
    });
  });
});
