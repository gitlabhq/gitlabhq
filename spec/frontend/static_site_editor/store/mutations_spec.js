import createState from '~/static_site_editor/store/state';
import mutations from '~/static_site_editor/store/mutations';
import * as types from '~/static_site_editor/store/mutation_types';
import { sourceContentTitle as title, sourceContent as content } from '../mock_data';

describe('Static Site Editor Store mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('loadContent', () => {
    beforeEach(() => {
      mutations[types.LOAD_CONTENT](state);
    });

    it('sets isLoadingContent to true', () => {
      expect(state.isLoadingContent).toBe(true);
    });
  });

  describe('receiveContentSuccess', () => {
    const payload = { title, content };

    beforeEach(() => {
      mutations[types.RECEIVE_CONTENT_SUCCESS](state, payload);
    });

    it('sets current state to LOADING', () => {
      expect(state.isLoadingContent).toBe(false);
    });

    it('sets title', () => {
      expect(state.title).toBe(payload.title);
    });

    it('sets originalContent and content', () => {
      expect(state.content).toBe(payload.content);
      expect(state.originalContent).toBe(payload.content);
    });
  });

  describe('receiveContentError', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_CONTENT_ERROR](state);
    });

    it('sets current state to LOADING_ERROR', () => {
      expect(state.isLoadingContent).toBe(false);
    });
  });

  describe('setContent', () => {
    it('sets content', () => {
      mutations[types.SET_CONTENT](state, content);

      expect(state.content).toBe(content);
    });
  });
});
