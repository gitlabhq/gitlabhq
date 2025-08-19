import waitForPromises from 'helpers/wait_for_promises';
import * as storage from '~/lib/utils/local_storage';
import * as UserApi from '~/api/user_api';
import {
  createUserCountsManager,
  userCounts,
  destroyUserCountsManager,
  setGlobalTodoCount,
  retrieveUserCountsFromApi,
} from '~/super_sidebar/user_counts_manager';
import { fetchUserCounts } from '~/super_sidebar/user_counts_fetch';

jest.mock('~/lib/utils/local_storage');
jest.mock('~/api');

const USER_ID = 123;
const userCountDefaults = {
  todos: 1,
  assigned_issues: 2,
  assigned_merge_requests: 3,
  review_requested_merge_requests: 4,
};

const userCountUpdate = {
  todos: 123,
  assigned_issues: 456,
  assigned_merge_requests: 789,
  review_requested_merge_requests: 101112,
};

describe('User Count Manager', () => {
  let channelMock;
  let newBroadcastChannelMock;

  beforeEach(() => {
    jest.spyOn(document, 'removeEventListener');
    jest.spyOn(document, 'addEventListener');

    global.gon.current_user_id = USER_ID;

    channelMock = {
      postMessage: jest.fn(),
      close: jest.fn(),
    };
    newBroadcastChannelMock = jest.fn().mockImplementation(() => channelMock);

    Object.assign(userCounts, userCountDefaults, { last_update: 0 });

    global.BroadcastChannel = newBroadcastChannelMock;
  });

  describe('userCounts', () => {
    it('returns total_merge_requests', () => {
      expect(userCounts.total_merge_requests).toEqual(7);

      Object.assign(userCounts, userCountUpdate, { last_update: 0 });

      expect(userCounts.total_merge_requests).toEqual(101901);
    });
  });

  describe('createUserCountsManager', () => {
    beforeEach(() => {
      createUserCountsManager();
    });

    it('creates BroadcastChannel which updates counts on message received', () => {
      expect(newBroadcastChannelMock).toHaveBeenCalledWith(`user_counts_${USER_ID}`);
    });

    it('closes BroadCastchannel if called while already open', () => {
      expect(channelMock.close).not.toHaveBeenCalled();

      createUserCountsManager();

      expect(channelMock.close).toHaveBeenCalled();
    });

    describe('BroadcastChannel onmessage handler', () => {
      it('updates counts on message received', () => {
        expect(userCounts).toMatchObject(userCountDefaults);

        channelMock.onmessage({ data: { ...userCountUpdate, last_update: Date.now() } });

        expect(userCounts).toMatchObject(userCountUpdate);
      });

      it('ignores updates with older data', () => {
        expect(userCounts).toMatchObject(userCountDefaults);
        userCounts.last_update = Date.now();

        channelMock.onmessage({
          data: { ...userCountUpdate, last_update: userCounts.last_update - 1000 },
        });

        expect(userCounts).toMatchObject(userCountDefaults);
      });

      it('ignores unknown fields', () => {
        expect(userCounts).toMatchObject(userCountDefaults);

        channelMock.onmessage({ data: { ...userCountUpdate, i_am_unknown: 5 } });

        expect(userCounts).toMatchObject(userCountUpdate);
        expect(userCounts.i_am_unknown).toBeUndefined();
      });

      it('does not update total_merge_requests', () => {
        expect(userCounts).toMatchObject(userCountDefaults);
        expect(userCounts.total_merge_requests).toEqual(7);

        channelMock.onmessage({ data: { ...userCountUpdate, total_merge_requests: 22 } });

        expect(userCounts).toMatchObject(userCountUpdate);
        expect(userCounts.total_merge_requests).toEqual(101901);
      });
    });

    it('broadcasts user counts during initialization', () => {
      expect(channelMock.postMessage).toHaveBeenCalledWith(
        expect.objectContaining(userCountDefaults),
      );
    });

    it('setups event listener without leaking them', () => {
      expect(document.removeEventListener).toHaveBeenCalledWith(
        'userCounts:fetch',
        expect.any(Function),
      );
      expect(document.addEventListener).toHaveBeenCalledWith(
        'userCounts:fetch',
        expect.any(Function),
      );
      expect(document.removeEventListener).toHaveBeenCalledWith(
        'todo:toggle',
        expect.any(Function),
      );
      expect(document.addEventListener).toHaveBeenCalledWith('todo:toggle', expect.any(Function));
    });
  });

  describe('Event listener userCounts:fetch', () => {
    beforeEach(() => {
      jest.spyOn(UserApi, 'getUserCounts').mockResolvedValue({
        data: { ...userCountUpdate, merge_requests: 'FOO' },
      });
      createUserCountsManager();
    });

    describe('manually created event', () => {
      it('fetches counts from API, stores and rebroadcasts them', async () => {
        expect(userCounts).toMatchObject(userCountDefaults);

        document.dispatchEvent(new CustomEvent('userCounts:fetch'));
        await waitForPromises();

        expect(UserApi.getUserCounts).toHaveBeenCalled();
        expect(userCounts).toMatchObject(userCountUpdate);
        expect(channelMock.postMessage).toHaveBeenLastCalledWith(userCounts);
      });
    });

    describe('fetchUserCounts helper', () => {
      it('fetches counts from API, stores and rebroadcasts them', async () => {
        expect(userCounts).toMatchObject(userCountDefaults);

        fetchUserCounts();
        await waitForPromises();

        expect(UserApi.getUserCounts).toHaveBeenCalled();
        expect(userCounts).toMatchObject(userCountUpdate);
        expect(channelMock.postMessage).toHaveBeenLastCalledWith(userCounts);
      });
    });
  });

  describe('Event listener todo:toggle', () => {
    beforeEach(() => {
      createUserCountsManager();
      userCounts.todos = 10;
    });

    describe('with total count', () => {
      it.each([
        { count: 123, expected: 123 },
        { count: -500, expected: 0 },
        { count: 0, expected: 0 },
        { count: NaN, expected: 10 },
        { count: '99+', expected: 10 },
      ])(`with count: $count results in $expected`, ({ count, expected }) => {
        expect(userCounts.todos).toBe(10);

        document.dispatchEvent(new CustomEvent('todo:toggle', { detail: { count } }));

        expect(userCounts.todos).toBe(expected);
      });
    });

    describe('with diff on count', () => {
      it.each([
        { delta: 5, expected: 15 },
        { delta: -5, expected: 5 },
        { delta: 0, expected: 10 },
        { delta: -100, expected: 0 },
        { delta: NaN, expected: 10 },
        { delta: '99+', expected: 10 },
      ])(`with count: $diff results in $expected`, ({ delta, expected }) => {
        expect(userCounts.todos).toBe(10);

        document.dispatchEvent(new CustomEvent('todo:toggle', { detail: { delta } }));

        expect(userCounts.todos).toBe(expected);
      });
    });

    it('updates count over delta if both are defined', () => {
      expect(userCounts.todos).toBe(10);

      const detail = {
        count: 20,
        delta: -5,
      };

      document.dispatchEvent(new CustomEvent('todo:toggle', { detail }));

      expect(userCounts.todos).toBe(detail.count);
    });
  });

  describe('destroyUserCountsManager', () => {
    it('unregisters event handler', () => {
      expect(document.removeEventListener).not.toHaveBeenCalledWith();

      destroyUserCountsManager();

      expect(document.removeEventListener).toHaveBeenCalledWith(
        'userCounts:fetch',
        expect.any(Function),
      );
    });

    describe('when BroadcastChannel is not opened', () => {
      it('does nothing', () => {
        destroyUserCountsManager();
        expect(channelMock.close).not.toHaveBeenCalled();
      });
    });

    describe('when BroadcastChannel is opened', () => {
      beforeEach(() => {
        createUserCountsManager();
      });

      it('closes BroadcastChannel', () => {
        expect(channelMock.close).not.toHaveBeenCalled();

        destroyUserCountsManager();

        expect(channelMock.close).toHaveBeenCalled();
      });
    });
  });

  describe('setGlobalTodoCount', () => {
    beforeEach(() => {
      createUserCountsManager();
      channelMock.postMessage.mockClear();
    });

    describe('when called with invalid values', () => {
      it.each([undefined, null, '435', -12, Number.MAX_SAFE_INTEGER + 1])(
        `does nothing for %s`,
        (value) => {
          expect(userCounts.todos).toBe(userCountDefaults.todos);

          setGlobalTodoCount(value);

          expect(userCounts.todos).toBe(userCountDefaults.todos);
          expect(userCounts.todos).not.toBe(value);
          expect(channelMock.postMessage).not.toHaveBeenCalled();
        },
      );
    });

    describe('when called with valid values', () => {
      it.each([0, 3, 12023])(`does update the todos value and broadcast for %s`, (value) => {
        expect(userCounts.todos).not.toBe(value);

        setGlobalTodoCount(value);

        expect(userCounts.todos).toBe(value);
        expect(channelMock.postMessage).toHaveBeenCalledWith({
          last_update: Date.now(),
          todos: value,
        });
      });
    });
  });

  describe('retrieveUserCountsFromApi', () => {
    it('caches value after successful request', async () => {
      jest.spyOn(UserApi, 'getUserCounts').mockResolvedValue({
        data: { ...userCountUpdate, merge_requests: 'FOO' },
      });

      await retrieveUserCountsFromApi();

      expect(storage.saveStorageValue).toHaveBeenCalledWith('user_counts', expect.anything());
    });

    it('uses cached value after failed request', async () => {
      jest.spyOn(UserApi, 'getUserCounts').mockRejectedValueOnce();
      jest
        .spyOn(storage, 'getStorageValue')
        .mockReturnValue({ value: { assigned_merge_requests: 10 } });

      await retrieveUserCountsFromApi();

      expect(userCounts.assigned_merge_requests).toBe(10);
    });
  });
});
