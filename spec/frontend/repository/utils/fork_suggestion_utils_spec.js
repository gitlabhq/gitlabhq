import * as commonUtils from '~/lib/utils/common_utils';
import {
  canFork,
  showSingleFileEditorForkSuggestion,
  showWebIdeForkSuggestion,
  showForkSuggestion,
  isIdeTarget,
  forkSuggestionForSelectedEditor,
} from '~/repository/utils/fork_suggestion_utils';

jest.mock('~/lib/utils/common_utils');

describe('forkSuggestionUtils', () => {
  let userPermissions;
  const createUserPermissions = (createMergeRequestIn = true, forkProject = true) => ({
    createMergeRequestIn,
    forkProject,
  });

  beforeEach(() => {
    commonUtils.isLoggedIn.mockReturnValue(true);
    userPermissions = createUserPermissions();
  });

  describe('canFork', () => {
    it('returns true when all conditions are met', () => {
      expect(canFork(userPermissions, false)).toBe(true);
    });

    it('returns false when user is not logged in', () => {
      commonUtils.isLoggedIn.mockReturnValue(false);
      expect(canFork(userPermissions, false)).toBe(false);
    });

    it('returns false when project is using LFS', () => {
      expect(canFork(userPermissions, true)).toBe(false);
    });

    it('returns false when user cannot create merge request', () => {
      userPermissions = createUserPermissions(false, true);
      expect(canFork(userPermissions, false)).toBe(false);
    });

    it('returns false when user cannot fork project', () => {
      userPermissions = createUserPermissions(true, false);
      expect(canFork(userPermissions, false)).toBe(false);
    });
  });

  describe('showSingleFileEditorForkSuggestion', () => {
    it('returns true when user can fork but cannot modify blob', () => {
      expect(showSingleFileEditorForkSuggestion(userPermissions, false, false)).toBe(true);
    });

    it('returns false when user can fork and can modify blob', () => {
      expect(showSingleFileEditorForkSuggestion(userPermissions, false, true)).toBe(false);
    });
  });

  describe('showWebIdeForkSuggestion', () => {
    it('returns true when user can fork but cannot modify blob with Web IDE', () => {
      expect(showWebIdeForkSuggestion(userPermissions, false, false)).toBe(true);
    });

    it('returns false when user can fork and can modify blob with Web IDE', () => {
      expect(showWebIdeForkSuggestion(userPermissions, false, true)).toBe(false);
    });
  });

  describe('showForkSuggestion', () => {
    it('returns true when single file editor fork suggestion is true', () => {
      expect(
        showForkSuggestion(userPermissions, false, {
          canModifyBlob: false,
          canModifyBlobWithWebIde: true,
        }),
      ).toBe(true);
    });

    it('returns true when Web IDE fork suggestion is true', () => {
      expect(
        showForkSuggestion(userPermissions, false, {
          canModifyBlob: true,
          canModifyBlobWithWebIde: false,
        }),
      ).toBe(true);
    });

    it('returns false when both fork suggestions are false', () => {
      expect(
        showForkSuggestion(userPermissions, false, {
          canModifyBlob: true,
          canModifyBlobWithWebIde: true,
        }),
      ).toBe(false);
    });

    it('returns false when user cannot fork', () => {
      commonUtils.isLoggedIn.mockReturnValue(false);
      expect(
        showForkSuggestion(userPermissions, false, {
          canModifyBlob: false,
          canModifyBlobWithWebIde: false,
        }),
      ).toBe(false);
    });
  });

  describe('isIdeTarget', () => {
    it('returns true when target is "ide"', () => {
      expect(isIdeTarget('ide')).toBe(true);
    });

    it('returns false when target is not "ide"', () => {
      expect(isIdeTarget('simple')).toBe(false);
      expect(isIdeTarget('')).toBe(false);
      expect(isIdeTarget(null)).toBe(false);
      expect(isIdeTarget(undefined)).toBe(false);
    });
  });

  describe('forkSuggestionForSelectedEditor', () => {
    it('returns Web IDE fork suggestion when target is "ide"', () => {
      const webIdeSuggestion = true;
      const singleFileSuggestion = false;

      expect(forkSuggestionForSelectedEditor('ide', webIdeSuggestion, singleFileSuggestion)).toBe(
        webIdeSuggestion,
      );
    });

    it('returns single file editor fork suggestion when target is not "ide"', () => {
      const webIdeSuggestion = false;
      const singleFileSuggestion = true;

      expect(
        forkSuggestionForSelectedEditor('simple', webIdeSuggestion, singleFileSuggestion),
      ).toBe(singleFileSuggestion);
    });

    it('handles different combinations of suggestion values', () => {
      // Both true
      expect(forkSuggestionForSelectedEditor('ide', true, true)).toBe(true);
      expect(forkSuggestionForSelectedEditor('simple', true, true)).toBe(true);

      // Both false
      expect(forkSuggestionForSelectedEditor('ide', false, false)).toBe(false);
      expect(forkSuggestionForSelectedEditor('simple', false, false)).toBe(false);

      // Mixed values
      expect(forkSuggestionForSelectedEditor('ide', true, false)).toBe(true);
      expect(forkSuggestionForSelectedEditor('simple', false, true)).toBe(true);
    });
  });
});
