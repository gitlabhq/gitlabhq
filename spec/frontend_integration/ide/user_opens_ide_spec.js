import { screen } from '@testing-library/dom';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { useOverclockTimers } from 'test_helpers/utils/overclock_timers';
import { stubPerformanceWebAPI } from 'helpers/performance';
import * as ideHelper from './helpers/ide_helper';
import startWebIDE from './helpers/start';

describe('IDE: User opens IDE', () => {
  useOverclockTimers();

  let vm;
  let container;

  beforeEach(() => {
    stubPerformanceWebAPI();

    setHTMLFixture('<div class="webide-container"></div>');
    container = document.querySelector('.webide-container');
  });

  afterEach(() => {
    vm.$destroy();
    resetHTMLFixture();
  });

  it('shows loading indicator while the IDE is loading', () => {
    vm = startWebIDE(container);

    expect(container.querySelectorAll('.multi-file-loading-container')).toHaveLength(3);
  });

  describe('when the project is empty', () => {
    beforeEach(() => {
      vm = startWebIDE(container, { isRepoEmpty: true });
    });

    it('shows "No files" in the left sidebar', async () => {
      expect(await screen.findByText('No files')).toBeDefined();
    });

    it('shows a "New file" button', () => {
      const buttons = screen.queryAllByTitle('New file');

      expect(buttons.map((x) => x.tagName)).toContain('BUTTON');
    });
  });

  describe('when the file tree is loaded', () => {
    beforeEach(async () => {
      vm = startWebIDE(container);

      await screen.findByText('README'); // wait for file tree to load
    });

    it('shows a list of files in the left sidebar', () => {
      expect(ideHelper.getFilesList()).toEqual(
        expect.arrayContaining(['README', 'LICENSE', 'CONTRIBUTING.md']),
      );
    });

    it('shows empty state in the main editor window', async () => {
      expect(
        await screen.findByText(
          "Select a file from the left sidebar to begin editing. Afterwards, you'll be able to commit your changes.",
        ),
      ).toBeDefined();
    });

    it('shows commit button in disabled state', async () => {
      const button = await screen.findByTestId('begin-commit-button');

      expect(button.getAttribute('disabled')).toBeDefined();
    });

    it('shows branch/MR dropdown with master selected', async () => {
      const dropdown = await screen.findByTestId('ide-nav-dropdown');

      expect(dropdown.textContent).toContain('master');
    });
  });

  describe('a path to a text file is present in the URL', () => {
    beforeEach(async () => {
      vm = startWebIDE(container, { path: 'README.md' });

      await ideHelper.waitForTabToOpen('README.md');
    });

    it('opens the file and its contents are shown in Monaco', async () => {
      expect(await ideHelper.getEditorValue()).toContain('Sample repo for testing gitlab features');
    });
  });

  describe('a path to a binary file is present in the URL', () => {
    beforeEach(async () => {
      vm = startWebIDE(container, { path: 'Gemfile.zip' });

      await ideHelper.waitForTabToOpen('Gemfile.zip');
    });

    it('shows download viewer', async () => {
      const downloadButton = await screen.findByText('Download');

      expect(downloadButton.getAttribute('download')).toEqual('Gemfile.zip');
      expect(downloadButton.getAttribute('href')).toContain('/raw/');
    });
  });

  describe('a path to an image is present in the URL', () => {
    beforeEach(async () => {
      vm = startWebIDE(container, { path: 'files/images/logo-white.png' });

      await ideHelper.waitForTabToOpen('logo-white.png');
    });

    it('shows image viewer', async () => {
      const viewer = await screen.findByTestId('image-viewer');
      const img = viewer.querySelector('img');

      expect(img.src).toContain('logo-white.png');
    });
  });

  describe('path in URL is a directory', () => {
    beforeEach(async () => {
      vm = startWebIDE(container, { path: 'files/images' });

      // wait for folders in left sidebar to be expanded
      await screen.findByText('images');
    });

    it('expands folders in the left sidebar', () => {
      expect(ideHelper.getFilesList()).toEqual(
        expect.arrayContaining(['files', 'images', 'logo-white.png', 'logo-black.png']),
      );
    });

    it('shows empty state in the main editor window', async () => {
      expect(
        await screen.findByText(
          "Select a file from the left sidebar to begin editing. Afterwards, you'll be able to commit your changes.",
        ),
      ).toBeDefined();
    });
  });

  describe("a file for path in url doesn't exist in the repo", () => {
    beforeEach(async () => {
      vm = startWebIDE(container, { path: 'abracadabra/hocus-focus.txt' });

      await ideHelper.waitForTabToOpen('hocus-focus.txt');
    });

    it('create new folders and file in the left sidebar', () => {
      expect(ideHelper.getFilesList()).toEqual(
        expect.arrayContaining(['abracadabra', 'hocus-focus.txt']),
      );
    });

    it('creates a blank new file', async () => {
      expect(await ideHelper.getEditorValue()).toEqual('\n');
    });
  });
});
