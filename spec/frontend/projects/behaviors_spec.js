import { initFindFileShortcut } from '~/projects/behaviors';
import Shortcuts from '~/behaviors/shortcuts/shortcuts';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

describe('initFindFileShortcut', () => {
  const fixture = '<button class="shortcuts-find-file">Find file</button>';

  beforeEach(() => setHTMLFixture(fixture));

  afterEach(() => resetHTMLFixture());

  it('add a `click` eventListener to the find file button', () => {
    const findFileButton = document.querySelector('.shortcuts-find-file');
    jest.spyOn(findFileButton, 'addEventListener');

    initFindFileShortcut();

    expect(findFileButton.addEventListener).toHaveBeenCalledWith(
      'click',
      Shortcuts.focusSearchFile,
    );
  });
});
