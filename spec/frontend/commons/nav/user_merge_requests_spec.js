import {
  openUserCountsBroadcast,
  closeUserCountsBroadcast,
  refreshUserMergeRequestCounts,
} from '~/commons/nav/user_merge_requests';
import Api from '~/api';

jest.mock('~/api');

const TEST_COUNT = 1000;
const MR_COUNT_CLASS = 'merge-requests-count';

describe('User Merge Requests', () => {
  let channelMock;
  let newBroadcastChannelMock;

  beforeEach(() => {
    global.gon.current_user_id = 123;

    channelMock = {
      postMessage: jest.fn(),
      close: jest.fn(),
    };
    newBroadcastChannelMock = jest.fn().mockImplementation(() => channelMock);

    global.BroadcastChannel = newBroadcastChannelMock;
    setFixtures(`<div class="${MR_COUNT_CLASS}">0</div>`);
  });

  const findMRCountText = () => document.body.querySelector(`.${MR_COUNT_CLASS}`).textContent;

  describe('refreshUserMergeRequestCounts', () => {
    beforeEach(() => {
      Api.userCounts.mockReturnValue(
        Promise.resolve({
          data: { merge_requests: TEST_COUNT },
        }),
      );
    });

    describe('with open broadcast channel', () => {
      beforeEach(() => {
        openUserCountsBroadcast();

        return refreshUserMergeRequestCounts();
      });

      it('updates the top count of merge requests', () => {
        expect(findMRCountText()).toEqual(TEST_COUNT.toLocaleString());
      });

      it('calls the API', () => {
        expect(Api.userCounts).toHaveBeenCalled();
      });

      it('posts count to BroadcastChannel', () => {
        expect(channelMock.postMessage).toHaveBeenCalledWith(TEST_COUNT);
      });
    });

    describe('without open broadcast channel', () => {
      beforeEach(() => refreshUserMergeRequestCounts());

      it('does not post anything', () => {
        expect(channelMock.postMessage).not.toHaveBeenCalled();
      });
    });
  });

  describe('openUserCountsBroadcast', () => {
    beforeEach(() => {
      openUserCountsBroadcast();
    });

    it('creates BroadcastChannel that updates DOM on message received', () => {
      expect(findMRCountText()).toEqual('0');

      channelMock.onmessage({ data: TEST_COUNT });

      expect(findMRCountText()).toEqual(TEST_COUNT.toLocaleString());
    });

    it('closes if called while already open', () => {
      expect(channelMock.close).not.toHaveBeenCalled();

      openUserCountsBroadcast();

      expect(channelMock.close).toHaveBeenCalled();
    });
  });

  describe('closeUserCountsBroadcast', () => {
    describe('when not opened', () => {
      it('does nothing', () => {
        expect(channelMock.close).not.toHaveBeenCalled();
      });
    });

    describe('when opened', () => {
      beforeEach(() => {
        openUserCountsBroadcast();
      });

      it('closes', () => {
        expect(channelMock.close).not.toHaveBeenCalled();

        closeUserCountsBroadcast();

        expect(channelMock.close).toHaveBeenCalled();
      });
    });
  });
});
