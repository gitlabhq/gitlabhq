import testAction from 'helpers/vuex_action_helper';
import createState from '~/static_site_editor/store/state';
import * as actions from '~/static_site_editor/store/actions';
import * as mutationTypes from '~/static_site_editor/store/mutation_types';
import loadSourceContent from '~/static_site_editor/services/load_source_content';

import createFlash from '~/flash';

import {
  projectId,
  sourcePath,
  sourceContentTitle as title,
  sourceContent as content,
} from '../mock_data';

jest.mock('~/flash');
jest.mock('~/static_site_editor/services/load_source_content', () => jest.fn());

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
});
