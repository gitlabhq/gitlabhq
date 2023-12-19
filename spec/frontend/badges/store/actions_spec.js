import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';
import actions, { transformBackendBadge } from '~/badges/store/actions';
import mutationTypes from '~/badges/store/mutation_types';
import createState from '~/badges/store/state';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { createDummyBadge, createDummyBadgeResponse } from '../dummy_badge';

describe('Badges store actions', () => {
  const dummyEndpointUrl = `${TEST_HOST}/badges/endpoint`;
  const dummyBadges = [
    { ...createDummyBadge(), id: 5 },
    { ...createDummyBadge(), id: 6 },
  ];

  let axiosMock;
  let badgeId;
  let state;

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    state = {
      ...createState(),
      apiEndpointUrl: dummyEndpointUrl,
      badges: dummyBadges,
    };
    badgeId = state.badges[0].id;
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('requestNewBadge', () => {
    it('commits REQUEST_NEW_BADGE', () => {
      return testAction(
        actions.requestNewBadge,
        null,
        state,
        [{ type: mutationTypes.REQUEST_NEW_BADGE }],
        [],
      );
    });
  });

  describe('receiveNewBadge', () => {
    it('commits RECEIVE_NEW_BADGE', () => {
      const newBadge = createDummyBadge();
      return testAction(
        actions.receiveNewBadge,
        newBadge,
        state,
        [{ type: mutationTypes.RECEIVE_NEW_BADGE, payload: newBadge }],
        [],
      );
    });
  });

  describe('receiveNewBadgeError', () => {
    it('commits RECEIVE_NEW_BADGE_ERROR', () => {
      return testAction(
        actions.receiveNewBadgeError,
        null,
        state,
        [{ type: mutationTypes.RECEIVE_NEW_BADGE_ERROR }],
        [],
      );
    });
  });

  describe('addBadge', () => {
    let badgeInAddForm;
    let dispatch;
    let endpointMock;

    beforeEach(() => {
      endpointMock = axiosMock.onPost(dummyEndpointUrl);
      dispatch = jest.fn();
      badgeInAddForm = createDummyBadge();
      state = {
        ...state,
        badgeInAddForm,
      };
    });

    it('dispatches requestNewBadge and receiveNewBadge for successful response', async () => {
      const dummyResponse = createDummyBadgeResponse();

      endpointMock.replyOnce((req) => {
        expect(req.data).toBe(
          JSON.stringify({
            name: 'TestBadge',
            image_url: badgeInAddForm.imageUrl,
            link_url: badgeInAddForm.linkUrl,
          }),
        );

        expect(dispatch.mock.calls).toEqual([['requestNewBadge']]);
        dispatch.mockClear();
        return [HTTP_STATUS_OK, dummyResponse];
      });

      const dummyBadge = transformBackendBadge(dummyResponse);

      await actions.addBadge({ state, dispatch });
      expect(dispatch.mock.calls).toEqual([['receiveNewBadge', dummyBadge]]);
    });

    it('dispatches requestNewBadge and receiveNewBadgeError for error response', async () => {
      endpointMock.replyOnce((req) => {
        expect(req.data).toBe(
          JSON.stringify({
            name: 'TestBadge',
            image_url: badgeInAddForm.imageUrl,
            link_url: badgeInAddForm.linkUrl,
          }),
        );

        expect(dispatch.mock.calls).toEqual([['requestNewBadge']]);
        dispatch.mockClear();
        return [HTTP_STATUS_INTERNAL_SERVER_ERROR, ''];
      });

      await expect(actions.addBadge({ state, dispatch })).rejects.toThrow();
      expect(dispatch.mock.calls).toEqual([['receiveNewBadgeError']]);
    });
  });

  describe('requestDeleteBadge', () => {
    it('commits REQUEST_DELETE_BADGE', () => {
      return testAction(
        actions.requestDeleteBadge,
        badgeId,
        state,
        [{ type: mutationTypes.REQUEST_DELETE_BADGE, payload: badgeId }],
        [],
      );
    });
  });

  describe('receiveDeleteBadge', () => {
    it('commits RECEIVE_DELETE_BADGE', () => {
      return testAction(
        actions.receiveDeleteBadge,
        badgeId,
        state,
        [{ type: mutationTypes.RECEIVE_DELETE_BADGE, payload: badgeId }],
        [],
      );
    });
  });

  describe('receiveDeleteBadgeError', () => {
    it('commits RECEIVE_DELETE_BADGE_ERROR', () => {
      return testAction(
        actions.receiveDeleteBadgeError,
        badgeId,
        state,
        [{ type: mutationTypes.RECEIVE_DELETE_BADGE_ERROR, payload: badgeId }],
        [],
      );
    });
  });

  describe('deleteBadge', () => {
    let dispatch;
    let endpointMock;

    beforeEach(() => {
      endpointMock = axiosMock.onDelete(`${dummyEndpointUrl}/${badgeId}`);
      dispatch = jest.fn();
    });

    it('dispatches requestDeleteBadge and receiveDeleteBadge for successful response', async () => {
      endpointMock.replyOnce(() => {
        expect(dispatch.mock.calls).toEqual([['requestDeleteBadge', badgeId]]);
        dispatch.mockClear();
        return [HTTP_STATUS_OK, ''];
      });

      await actions.deleteBadge({ state, dispatch }, { id: badgeId });
      expect(dispatch.mock.calls).toEqual([['receiveDeleteBadge', badgeId]]);
    });

    it('dispatches requestDeleteBadge and receiveDeleteBadgeError for error response', async () => {
      endpointMock.replyOnce(() => {
        expect(dispatch.mock.calls).toEqual([['requestDeleteBadge', badgeId]]);
        dispatch.mockClear();
        return [HTTP_STATUS_INTERNAL_SERVER_ERROR, ''];
      });

      await expect(actions.deleteBadge({ state, dispatch }, { id: badgeId })).rejects.toThrow();
      expect(dispatch.mock.calls).toEqual([['receiveDeleteBadgeError', badgeId]]);
    });
  });

  describe('editBadge', () => {
    it('commits START_EDITING', () => {
      const dummyBadge = createDummyBadge();
      return testAction(
        actions.editBadge,
        dummyBadge,
        state,
        [{ type: mutationTypes.START_EDITING, payload: dummyBadge }],
        [],
      );
    });
  });

  describe('requestLoadBadges', () => {
    it('commits REQUEST_LOAD_BADGES', () => {
      const dummyData = 'this is not real data';
      return testAction(
        actions.requestLoadBadges,
        dummyData,
        state,
        [{ type: mutationTypes.REQUEST_LOAD_BADGES, payload: dummyData }],
        [],
      );
    });
  });

  describe('receiveLoadBadges', () => {
    it('commits RECEIVE_LOAD_BADGES', () => {
      const badges = dummyBadges;
      return testAction(
        actions.receiveLoadBadges,
        badges,
        state,
        [{ type: mutationTypes.RECEIVE_LOAD_BADGES, payload: badges }],
        [],
      );
    });
  });

  describe('receiveLoadBadgesError', () => {
    it('commits RECEIVE_LOAD_BADGES_ERROR', () => {
      return testAction(
        actions.receiveLoadBadgesError,
        null,
        state,
        [{ type: mutationTypes.RECEIVE_LOAD_BADGES_ERROR }],
        [],
      );
    });
  });

  describe('loadBadges', () => {
    let dispatch;
    let endpointMock;

    beforeEach(() => {
      endpointMock = axiosMock.onGet(dummyEndpointUrl);
      dispatch = jest.fn();
    });

    it('dispatches requestLoadBadges and receiveLoadBadges for successful response', async () => {
      const dummyData = 'this is just some data';
      const dummyResponse = [
        createDummyBadgeResponse(),
        createDummyBadgeResponse(),
        createDummyBadgeResponse(),
      ];
      endpointMock.replyOnce(() => {
        expect(dispatch.mock.calls).toEqual([['requestLoadBadges', dummyData]]);
        dispatch.mockClear();
        return [HTTP_STATUS_OK, dummyResponse];
      });

      await actions.loadBadges({ state, dispatch }, dummyData);
      const badges = dummyResponse.map(transformBackendBadge);

      expect(dispatch.mock.calls).toEqual([['receiveLoadBadges', badges]]);
    });

    it('dispatches requestLoadBadges and receiveLoadBadgesError for error response', async () => {
      const dummyData = 'this is just some data';
      endpointMock.replyOnce(() => {
        expect(dispatch.mock.calls).toEqual([['requestLoadBadges', dummyData]]);
        dispatch.mockClear();
        return [HTTP_STATUS_INTERNAL_SERVER_ERROR, ''];
      });

      await expect(actions.loadBadges({ state, dispatch }, dummyData)).rejects.toThrow();
      expect(dispatch.mock.calls).toEqual([['receiveLoadBadgesError']]);
    });
  });

  describe('requestRenderedBadge', () => {
    it('commits REQUEST_RENDERED_BADGE', () => {
      return testAction(
        actions.requestRenderedBadge,
        null,
        state,
        [{ type: mutationTypes.REQUEST_RENDERED_BADGE }],
        [],
      );
    });
  });

  describe('receiveRenderedBadge', () => {
    it('commits RECEIVE_RENDERED_BADGE', () => {
      const dummyBadge = createDummyBadge();
      return testAction(
        actions.receiveRenderedBadge,
        dummyBadge,
        state,
        [{ type: mutationTypes.RECEIVE_RENDERED_BADGE, payload: dummyBadge }],
        [],
      );
    });
  });

  describe('receiveRenderedBadgeError', () => {
    it('commits RECEIVE_RENDERED_BADGE_ERROR', () => {
      return testAction(
        actions.receiveRenderedBadgeError,
        null,
        state,
        [{ type: mutationTypes.RECEIVE_RENDERED_BADGE_ERROR }],
        [],
      );
    });
  });

  describe('renderBadge', () => {
    let dispatch;
    let endpointMock;
    let badgeInForm;

    beforeEach(() => {
      badgeInForm = createDummyBadge();
      state = {
        ...state,
        badgeInAddForm: badgeInForm,
      };
      const urlParameters = [
        `link_url=${encodeURIComponent(badgeInForm.linkUrl)}`,
        `image_url=${encodeURIComponent(badgeInForm.imageUrl)}`,
      ].join('&');
      endpointMock = axiosMock.onGet(`${dummyEndpointUrl}/render?${urlParameters}`);
      dispatch = jest.fn();
    });

    it('returns immediately if imageUrl is empty', async () => {
      jest.spyOn(axios, 'get').mockImplementation(() => {});
      badgeInForm.imageUrl = '';

      await actions.renderBadge({ state, dispatch });
      expect(axios.get).not.toHaveBeenCalled();
    });

    it('returns immediately if linkUrl is empty', async () => {
      jest.spyOn(axios, 'get').mockImplementation(() => {});
      badgeInForm.linkUrl = '';

      await actions.renderBadge({ state, dispatch });
      expect(axios.get).not.toHaveBeenCalled();
    });

    it('escapes user input', async () => {
      jest
        .spyOn(axios, 'get')
        .mockImplementation(() => Promise.resolve({ data: createDummyBadgeResponse() }));
      badgeInForm.imageUrl = '&make-sandwich=true';
      badgeInForm.linkUrl = '<script>I am dangerous!</script>';

      await actions.renderBadge({ state, dispatch });
      expect(axios.get.mock.calls.length).toBe(1);
      const url = axios.get.mock.calls[0][0];

      expect(url).toMatch(new RegExp(`^${dummyEndpointUrl}/render?`));
      expect(url).toMatch(/\\?link_url=%3Cscript%3EI%20am%20dangerous!%3C%2Fscript%3E&/);
      expect(url).toMatch(/&image_url=%26make-sandwich%3Dtrue$/);
    });

    it('dispatches requestRenderedBadge and receiveRenderedBadge for successful response', async () => {
      const dummyResponse = createDummyBadgeResponse();
      endpointMock.replyOnce(() => {
        expect(dispatch.mock.calls).toEqual([['requestRenderedBadge']]);
        dispatch.mockClear();
        return [HTTP_STATUS_OK, dummyResponse];
      });

      await actions.renderBadge({ state, dispatch });
      const renderedBadge = transformBackendBadge(dummyResponse);

      expect(dispatch.mock.calls).toEqual([['receiveRenderedBadge', renderedBadge]]);
    });

    it('dispatches requestRenderedBadge and receiveRenderedBadgeError for error response', async () => {
      endpointMock.replyOnce(() => {
        expect(dispatch.mock.calls).toEqual([['requestRenderedBadge']]);
        dispatch.mockClear();
        return [HTTP_STATUS_INTERNAL_SERVER_ERROR, ''];
      });

      await expect(actions.renderBadge({ state, dispatch })).rejects.toThrow();
      expect(dispatch.mock.calls).toEqual([['receiveRenderedBadgeError']]);
    });
  });

  describe('requestUpdatedBadge', () => {
    it('commits REQUEST_UPDATED_BADGE', () => {
      return testAction(
        actions.requestUpdatedBadge,
        null,
        state,
        [{ type: mutationTypes.REQUEST_UPDATED_BADGE }],
        [],
      );
    });
  });

  describe('receiveUpdatedBadge', () => {
    it('commits RECEIVE_UPDATED_BADGE', () => {
      const updatedBadge = createDummyBadge();
      return testAction(
        actions.receiveUpdatedBadge,
        updatedBadge,
        state,
        [{ type: mutationTypes.RECEIVE_UPDATED_BADGE, payload: updatedBadge }],
        [],
      );
    });
  });

  describe('receiveUpdatedBadgeError', () => {
    it('commits RECEIVE_UPDATED_BADGE_ERROR', () => {
      return testAction(
        actions.receiveUpdatedBadgeError,
        null,
        state,
        [{ type: mutationTypes.RECEIVE_UPDATED_BADGE_ERROR }],
        [],
      );
    });
  });

  describe('saveBadge', () => {
    let badgeInEditForm;
    let dispatch;
    let endpointMock;

    beforeEach(() => {
      badgeInEditForm = createDummyBadge();
      state = {
        ...state,
        badgeInEditForm,
      };
      endpointMock = axiosMock.onPut(`${dummyEndpointUrl}/${badgeInEditForm.id}`);
      dispatch = jest.fn();
    });

    it('dispatches requestUpdatedBadge and receiveUpdatedBadge for successful response', async () => {
      const dummyResponse = createDummyBadgeResponse();

      endpointMock.replyOnce((req) => {
        expect(req.data).toBe(
          JSON.stringify({
            name: 'TestBadge',
            image_url: badgeInEditForm.imageUrl,
            link_url: badgeInEditForm.linkUrl,
          }),
        );

        expect(dispatch.mock.calls).toEqual([['requestUpdatedBadge']]);
        dispatch.mockClear();
        return [HTTP_STATUS_OK, dummyResponse];
      });

      const updatedBadge = transformBackendBadge(dummyResponse);
      await actions.saveBadge({ state, dispatch });
      expect(dispatch.mock.calls).toEqual([['receiveUpdatedBadge', updatedBadge]]);
    });

    it('dispatches requestUpdatedBadge and receiveUpdatedBadgeError for error response', async () => {
      endpointMock.replyOnce((req) => {
        expect(req.data).toBe(
          JSON.stringify({
            name: 'TestBadge',
            image_url: badgeInEditForm.imageUrl,
            link_url: badgeInEditForm.linkUrl,
          }),
        );

        expect(dispatch.mock.calls).toEqual([['requestUpdatedBadge']]);
        dispatch.mockClear();
        return [HTTP_STATUS_INTERNAL_SERVER_ERROR, ''];
      });

      await expect(actions.saveBadge({ state, dispatch })).rejects.toThrow();
      expect(dispatch.mock.calls).toEqual([['receiveUpdatedBadgeError']]);
    });
  });

  describe('stopEditing', () => {
    it('commits STOP_EDITING', () => {
      return testAction(
        actions.stopEditing,
        null,
        state,
        [{ type: mutationTypes.STOP_EDITING }],
        [],
      );
    });
  });

  describe('updateBadgeInForm', () => {
    it('commits UPDATE_BADGE_IN_FORM', () => {
      const dummyBadge = createDummyBadge();
      return testAction(
        actions.updateBadgeInForm,
        dummyBadge,
        state,
        [{ type: mutationTypes.UPDATE_BADGE_IN_FORM, payload: dummyBadge }],
        [],
      );
    });

    describe('updateBadgeInModal', () => {
      it('commits UPDATE_BADGE_IN_MODAL', () => {
        const dummyBadge = createDummyBadge();
        return testAction(
          actions.updateBadgeInModal,
          dummyBadge,
          state,
          [{ type: mutationTypes.UPDATE_BADGE_IN_MODAL, payload: dummyBadge }],
          [],
        );
      });
    });
  });
});
