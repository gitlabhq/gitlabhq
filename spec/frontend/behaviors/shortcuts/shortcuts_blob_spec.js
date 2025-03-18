import ShortcutsBlob from '~/behaviors/shortcuts/shortcuts_blob';
import { PROJECT_FILES_GO_TO_PERMALINK } from '~/behaviors/shortcuts/keybindings';
import { moveToFilePermalink } from '~/blob/utils';

describe('ShortcutsBlob', () => {
  const shortcuts = {
    add: jest.fn(),
  };

  const init = () => {
    return new ShortcutsBlob(shortcuts);
  };

  beforeEach(() => {
    shortcuts.add.mockClear();
    window.gon = {};
  });

  describe('constructor', () => {
    describe('when shortcuts should be added', () => {
      it('adds the permalink shortcut when gon.features is undefined', () => {
        init();

        expect(shortcuts.add).toHaveBeenCalledWith(
          PROJECT_FILES_GO_TO_PERMALINK,
          moveToFilePermalink,
        );
      });

      it('adds shortcuts when blobOverflowMenu is false', () => {
        window.gon.features = {
          blobOverflowMenu: false,
        };

        init();

        expect(shortcuts.add).toHaveBeenCalledWith(
          PROJECT_FILES_GO_TO_PERMALINK,
          moveToFilePermalink,
        );
      });
    });

    describe('when shortcuts should not be added', () => {
      it('does not add shortcuts when blobOverflowMenu is true', () => {
        window.gon.features = {
          blobOverflowMenu: true,
        };

        init();

        expect(shortcuts.add).not.toHaveBeenCalled();
      });
    });
  });
});
