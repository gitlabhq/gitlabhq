import * as Sentry from '@sentry/browser';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/emoji/awards_app/store/actions';
import axios from '~/lib/utils/axios_utils';

jest.mock('@sentry/browser');

describe('Awards app actions', () => {
  describe('setInitialData', () => {
    it('commits SET_INITIAL_DATA', async () => {
      await testAction(
        actions.setInitialData,
        { path: 'https://gitlab.com' },
        {},
        [{ type: 'SET_INITIAL_DATA', payload: { path: 'https://gitlab.com' } }],
        [],
      );
    });
  });

  describe('fetchAwards', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      beforeEach(() => {
        mock
          .onGet('/awards', { params: { per_page: 100, page: '1' } })
          .reply(200, ['thumbsup'], { 'x-next-page': '2' });
        mock.onGet('/awards', { params: { per_page: 100, page: '2' } }).reply(200, ['thumbsdown']);
      });

      it('commits FETCH_AWARDS_SUCCESS', async () => {
        await testAction(
          actions.fetchAwards,
          '1',
          { path: '/awards' },
          [{ type: 'FETCH_AWARDS_SUCCESS', payload: ['thumbsup'] }],
          [{ type: 'fetchAwards', payload: '2' }],
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet('/awards').reply(500);
      });

      it('calls Sentry.captureException', async () => {
        await testAction(actions.fetchAwards, null, { path: '/awards' }, [], [], () => {
          expect(Sentry.captureException).toHaveBeenCalled();
        });
      });
    });
  });

  describe('toggleAward', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('adding new award', () => {
      describe('success', () => {
        beforeEach(() => {
          mock.onPost('/awards').reply(200, { id: 1 });
        });

        it('commits ADD_NEW_AWARD', async () => {
          testAction(actions.toggleAward, null, { path: '/awards', awards: [] }, [
            { type: 'ADD_NEW_AWARD', payload: { id: 1 } },
          ]);
        });
      });

      describe('error', () => {
        beforeEach(() => {
          mock.onPost('/awards').reply(500);
        });

        it('calls Sentry.captureException', async () => {
          await testAction(
            actions.toggleAward,
            null,
            { path: '/awards', awards: [] },
            [],
            [],
            () => {
              expect(Sentry.captureException).toHaveBeenCalled();
            },
          );
        });
      });
    });

    describe('removing a award', () => {
      const mockData = { id: 1, name: 'thumbsup', user: { id: 1 } };

      describe('success', () => {
        beforeEach(() => {
          mock.onDelete('/awards/1').reply(200);
        });

        it('commits REMOVE_AWARD', async () => {
          testAction(
            actions.toggleAward,
            'thumbsup',
            {
              path: '/awards',
              currentUserId: 1,
              awards: [mockData],
            },
            [{ type: 'REMOVE_AWARD', payload: 1 }],
          );
        });
      });

      describe('error', () => {
        beforeEach(() => {
          mock.onDelete('/awards/1').reply(500);
        });

        it('calls Sentry.captureException', async () => {
          await testAction(
            actions.toggleAward,
            'thumbsup',
            {
              path: '/awards',
              currentUserId: 1,
              awards: [mockData],
            },
            [],
            [],
            () => {
              expect(Sentry.captureException).toHaveBeenCalled();
            },
          );
        });
      });
    });
  });
});
