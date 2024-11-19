import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';
import actions, { transformBackendBadge } from '~/badges/store/actions';
import mutationTypes from '~/badges/store/mutation_types';
import createState from '~/badges/store/state';
import { INITIAL_PAGE, PAGE_SIZE } from '~/badges/constants';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { createDummyBadge, createDummyBadgeResponse } from '../dummy_badge';
import { MOCK_PAGINATION, MOCK_PAGINATION_HEADERS } from '../mock_data';

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
      pagination: MOCK_PAGINATION,
    };
    badgeId = state.badges[0].id;
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('addBadge', () => {
    let badgeInAddForm;
    let endpointMock;

    beforeEach(() => {
      endpointMock = axiosMock.onPost(dummyEndpointUrl);
      badgeInAddForm = createDummyBadge();
      state = {
        ...state,
        badgeInAddForm,
      };
    });

    it('commits REQUEST_NEW_BADGE, commits RECEIVE_NEW_BADGE, and dispatches loadBadges for the current page on successful response', () => {
      endpointMock.replyOnce((req) => {
        expect(req.data).toBe(
          JSON.stringify({
            name: badgeInAddForm.name,
            image_url: badgeInAddForm.imageUrl,
            link_url: badgeInAddForm.linkUrl,
          }),
        );

        return [HTTP_STATUS_OK, createDummyBadgeResponse()];
      });

      return testAction({
        action: actions.addBadge,
        state,
        expectedMutations: [
          { type: mutationTypes.REQUEST_NEW_BADGE },
          { type: mutationTypes.RECEIVE_NEW_BADGE },
        ],
        expectedActions: [{ type: 'loadBadges', payload: { page: state.pagination.page } }],
      });
    });

    it('commits REQUEST_NEW_BADGE, commits RECEIVE_NEW_BADGE_ERROR, and throws an error on error response', () => {
      endpointMock.replyOnce((req) => {
        expect(req.data).toBe(
          JSON.stringify({
            name: badgeInAddForm.name,
            image_url: badgeInAddForm.imageUrl,
            link_url: badgeInAddForm.linkUrl,
          }),
        );

        return [HTTP_STATUS_INTERNAL_SERVER_ERROR, 'mock_new_badge_error'];
      });

      return testAction({
        action: actions.addBadge,
        state,
        expectedMutations: [
          { type: mutationTypes.REQUEST_NEW_BADGE },
          { type: mutationTypes.RECEIVE_NEW_BADGE_ERROR },
        ],
      }).catch(({ response }) => {
        expect(response.status).toBe(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        expect(response.data).toBe('mock_new_badge_error');
      });
    });
  });

  describe('deleteBadge', () => {
    let endpointMock;

    beforeEach(() => {
      endpointMock = axiosMock.onDelete(`${dummyEndpointUrl}/${badgeId}`);
    });

    it('commits REQUEST_DELETE_BADGE and dispatches loadBadges for the current page on successful response', () => {
      endpointMock.replyOnce((req) => {
        expect(req.url).toBe(`${dummyEndpointUrl}/${badgeId}`);
        return [HTTP_STATUS_OK, ''];
      });

      return testAction({
        action: actions.deleteBadge,
        payload: state.badges[0],
        state,
        expectedMutations: [{ type: mutationTypes.REQUEST_DELETE_BADGE, payload: badgeId }],
        expectedActions: [{ type: 'loadBadges', payload: { page: state.pagination.page } }],
      });
    });

    it('commits REQUEST_DELETE_BADGE, commits RECEIVE_DELETE_BADGE_ERROR, and throws an error on error response', () => {
      endpointMock.replyOnce((req) => {
        expect(req.url).toBe(`${dummyEndpointUrl}/${badgeId}`);
        return [HTTP_STATUS_INTERNAL_SERVER_ERROR, 'mock_delete_badge_error'];
      });

      return testAction({
        action: actions.deleteBadge,
        payload: state.badges[0],
        state,
        expectedMutations: [
          { type: mutationTypes.REQUEST_DELETE_BADGE, payload: badgeId },
          { type: mutationTypes.RECEIVE_DELETE_BADGE_ERROR, payload: badgeId },
        ],
      }).catch(({ response }) => {
        expect(response.status).toBe(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        expect(response.data).toBe('mock_delete_badge_error');
      });
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

  describe('loadBadges', () => {
    let endpointMock;

    beforeEach(() => {
      endpointMock = axiosMock.onGet(dummyEndpointUrl);
    });

    it('commits REQUEST_LOAD_BADGES, commits RECEIVE_LOAD_BADGES, and commits RECEIVE_PAGINATION on successful response', () => {
      const dummyResponse = [
        createDummyBadgeResponse(),
        createDummyBadgeResponse(),
        createDummyBadgeResponse(),
      ];

      endpointMock.replyOnce((req) => {
        expect(req.params).toStrictEqual({
          page: INITIAL_PAGE,
          per_page: PAGE_SIZE,
        });

        return [HTTP_STATUS_OK, dummyResponse, MOCK_PAGINATION_HEADERS];
      });

      return testAction({
        action: actions.loadBadges,
        payload: { page: INITIAL_PAGE },
        state,
        expectedMutations: [
          { type: mutationTypes.REQUEST_LOAD_BADGES },
          {
            type: mutationTypes.RECEIVE_LOAD_BADGES,
            payload: dummyResponse.map(transformBackendBadge),
          },
          { type: mutationTypes.RECEIVE_PAGINATION, payload: MOCK_PAGINATION },
        ],
      });
    });

    it('commits REQUEST_NEW_BADGE, commits RECEIVE_NEW_BADGE_ERROR, and throws an error on error response', () => {
      endpointMock.replyOnce((req) => {
        expect(req.params).toStrictEqual({
          page: INITIAL_PAGE,
          per_page: PAGE_SIZE,
        });

        return [HTTP_STATUS_INTERNAL_SERVER_ERROR, 'mock_load_badges_error'];
      });

      return testAction({
        action: actions.loadBadges,
        payload: { page: INITIAL_PAGE },
        state,
        expectedMutations: [
          { type: mutationTypes.REQUEST_LOAD_BADGES },
          { type: mutationTypes.RECEIVE_LOAD_BADGES_ERROR },
        ],
      }).catch(({ response }) => {
        expect(response.status).toBe(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        expect(response.data).toBe('mock_load_badges_error');
      });
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

    it('returns immediately if imageUrl is invalid', async () => {
      jest.spyOn(axios, 'get').mockImplementation(() => {});
      badgeInForm.imageUrl = 'foo';

      await actions.renderBadge({ state, dispatch });
      expect(axios.get).not.toHaveBeenCalled();
    });

    it('returns immediately if linkUrl is invalid', async () => {
      jest.spyOn(axios, 'get').mockImplementation(() => {});
      badgeInForm.linkUrl = 'foo';

      await actions.renderBadge({ state, dispatch });
      expect(axios.get).not.toHaveBeenCalled();
    });

    it('escapes user input', async () => {
      jest
        .spyOn(axios, 'get')
        .mockImplementation(() => Promise.resolve({ data: createDummyBadgeResponse() }));
      badgeInForm.imageUrl = "https://example.com?param=<script>alert('XSS')</script>";
      badgeInForm.linkUrl = "https://example.com?param=<script>alert('XSS')</script>";

      await actions.renderBadge({ state, dispatch });
      expect(axios.get.mock.calls.length).toBe(1);
      const url = axios.get.mock.calls[0][0];

      expect(url).toContain(
        "/render?link_url=https%3A%2F%2Fexample.com%3Fparam%3D%3Cscript%3Ealert('XSS')%3C%2Fscript%3E&image_url=https%3A%2F%2Fexample.com%3Fparam%3D%3Cscript%3Ealert('XSS')%3C%2Fscript%3E",
      );
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
