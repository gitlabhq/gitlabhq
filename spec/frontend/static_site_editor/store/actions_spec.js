import testAction from 'helpers/vuex_action_helper';
import createState from '~/static_site_editor/store/state';
import * as actions from '~/static_site_editor/store/actions';
import * as mutationTypes from '~/static_site_editor/store/mutation_types';
import loadSourceContent from '~/static_site_editor/services/load_source_content';
import submitContentChanges from '~/static_site_editor/services/submit_content_changes';

import createFlash from '~/flash';

import {
  username,
  projectId,
  sourcePath,
  sourceContentTitle as title,
  sourceContent as content,
  savedContentMeta,
  submitChangesError,
} from '../mock_data';

jest.mock('~/flash');
jest.mock('~/static_site_editor/services/load_source_content', () => jest.fn());
jest.mock('~/static_site_editor/services/submit_content_changes', () => jest.fn());

describe('Static Site Editor Store actions', () => {
  let state;

  beforeEach(() => {
    state = createState({
      projectId,
      sourcePath,
    });
  });

  describe('loadContent', () => {
    describe('on success', () => {
      const payload = { title, content };

      beforeEach(() => {
        loadSourceContent.mockResolvedValueOnce(payload);
      });

      it('commits receiveContentSuccess', () => {
        testAction(
          actions.loadContent,
          null,
          state,
          [
            { type: mutationTypes.LOAD_CONTENT },
            { type: mutationTypes.RECEIVE_CONTENT_SUCCESS, payload },
          ],
          [],
        );

        expect(loadSourceContent).toHaveBeenCalledWith({ projectId, sourcePath });
      });
    });

    describe('on error', () => {
      const expectedMutations = [
        { type: mutationTypes.LOAD_CONTENT },
        { type: mutationTypes.RECEIVE_CONTENT_ERROR },
      ];

      beforeEach(() => {
        loadSourceContent.mockRejectedValueOnce();
      });

      it('commits receiveContentError', () => {
        testAction(actions.loadContent, null, state, expectedMutations);
      });

      it('displays flash communicating error', () => {
        return testAction(actions.loadContent, null, state, expectedMutations).then(() => {
          expect(createFlash).toHaveBeenCalledWith(
            'An error ocurred while loading your content. Please try again.',
          );
        });
      });
    });
  });

  describe('setContent', () => {
    it('commits setContent mutation', () => {
      testAction(actions.setContent, content, state, [
        {
          type: mutationTypes.SET_CONTENT,
          payload: content,
        },
      ]);
    });
  });

  describe('submitChanges', () => {
    describe('on success', () => {
      beforeEach(() => {
        state = createState({
          projectId,
          content,
          username,
          sourcePath,
        });
        submitContentChanges.mockResolvedValueOnce(savedContentMeta);
      });

      it('commits submitChangesSuccess mutation', () => {
        testAction(
          actions.submitChanges,
          null,
          state,
          [
            { type: mutationTypes.SUBMIT_CHANGES },
            { type: mutationTypes.SUBMIT_CHANGES_SUCCESS, payload: savedContentMeta },
          ],
          [],
        );

        expect(submitContentChanges).toHaveBeenCalledWith({
          username,
          projectId,
          content,
          sourcePath,
        });
      });
    });

    describe('on error', () => {
      const error = new Error(submitChangesError);
      const expectedMutations = [
        { type: mutationTypes.SUBMIT_CHANGES },
        { type: mutationTypes.SUBMIT_CHANGES_ERROR, payload: error.message },
      ];

      beforeEach(() => {
        submitContentChanges.mockRejectedValueOnce(error);
      });

      it('dispatches receiveContentError', () => {
        testAction(actions.submitChanges, null, state, expectedMutations);
      });
    });
  });

  describe('dismissSubmitChangesError', () => {
    it('commits dismissSubmitChangesError', () => {
      testAction(actions.dismissSubmitChangesError, null, state, [
        {
          type: mutationTypes.DISMISS_SUBMIT_CHANGES_ERROR,
        },
      ]);
    });
  });
});
