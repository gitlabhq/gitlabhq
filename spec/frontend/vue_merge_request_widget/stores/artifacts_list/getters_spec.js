import { title } from '~/vue_merge_request_widget/stores/artifacts_list/getters';
import state from '~/vue_merge_request_widget/stores/artifacts_list/state';
import { artifacts } from '../../mock_data';

describe('Artifacts Store Getters', () => {
  let localState;

  beforeEach(() => {
    localState = state();
  });

  describe('title', () => {
    describe('when is loading', () => {
      it('returns loading message', () => {
        localState.isLoading = true;
        expect(title(localState)).toBe('Loading artifacts');
      });
    });
    describe('when has error', () => {
      it('returns error message', () => {
        localState.hasError = true;
        expect(title(localState)).toBe('An error occurred while fetching the artifacts');
      });
    });
    describe('when it has artifacts', () => {
      it('returns artifacts message', () => {
        localState.artifacts = artifacts;
        expect(title(localState)).toBe('View 2 exposed artifacts');
      });
    });
  });
});
