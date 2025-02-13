import { createAlert, VARIANT_INFO } from '~/alert';
import * as commonUtils from '~/lib/utils/common_utils';
import {
  showForkSuggestionAlert,
  canFork,
  showSingleFileEditorForkSuggestion,
  showWebIdeForkSuggestion,
  showForkSuggestion,
} from '~/repository/utils/fork_suggestion_utils';

jest.mock('~/alert');
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

  describe('showForkSuggestionAlert', () => {
    const forkAndViewPath = '/path/to/fork';

    beforeEach(() => {
      createAlert.mockClear();
    });

    it('calls createAlert with correct parameters', () => {
      showForkSuggestionAlert(forkAndViewPath);

      expect(createAlert).toHaveBeenCalledTimes(1);
      expect(createAlert).toHaveBeenCalledWith({
        message:
          "You can't edit files directly in this project. Fork this project and submit a merge request with your changes.",
        variant: VARIANT_INFO,
        primaryButton: {
          text: 'Fork',
          link: forkAndViewPath,
        },
        secondaryButton: {
          text: 'Cancel',
          clickHandler: expect.any(Function),
        },
      });
    });

    it('secondary button click handler dismisses the alert', () => {
      const mockAlert = { dismiss: jest.fn() };
      createAlert.mockReturnValue(mockAlert);

      showForkSuggestionAlert(forkAndViewPath);

      const secondaryButtonClickHandler = createAlert.mock.calls[0][0].secondaryButton.clickHandler;
      secondaryButtonClickHandler(mockAlert);

      expect(mockAlert.dismiss).toHaveBeenCalledTimes(1);
    });
  });
});
