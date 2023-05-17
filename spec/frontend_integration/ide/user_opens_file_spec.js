import { screen } from '@testing-library/dom';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { useOverclockTimers } from 'test_helpers/utils/overclock_timers';
import { stubPerformanceWebAPI } from 'helpers/performance';
import * as ideHelper from './helpers/ide_helper';
import startWebIDE from './helpers/start';

describe('IDE: User opens a file in the Web IDE', () => {
  useOverclockTimers();

  let vm;
  let container;

  beforeEach(async () => {
    stubPerformanceWebAPI();
    setHTMLFixture('<div class="webide-container"></div>');
    container = document.querySelector('.webide-container');

    vm = startWebIDE(container);

    await screen.findByText('README'); // wait for file tree to load
  });

  afterEach(() => {
    vm.$destroy();
    resetHTMLFixture();
  });

  describe('user opens a directory', () => {
    beforeEach(async () => {
      await ideHelper.openFile('files/images');
      await screen.findByText('logo-white.png');
    });

    it('expands directory in the left sidebar', () => {
      expect(ideHelper.getFilesList()).toEqual(
        expect.arrayContaining(['html', 'js', 'images', 'logo-white.png']),
      );
    });
  });

  describe('user opens a text file', () => {
    beforeEach(async () => {
      await ideHelper.openFile('README.md');
      await ideHelper.waitForTabToOpen('README.md');
    });

    it('opens the file in monaco editor', async () => {
      expect(await ideHelper.getEditorValue()).toContain('Sample repo for testing gitlab features');
    });

    describe('user switches to review mode', () => {
      beforeEach(() => {
        ideHelper.switchLeftSidebarTab('Review');
      });

      it('shows diff editor', async () => {
        expect(await ideHelper.findMonacoDiffEditor()).toBeDefined();
      });
    });
  });

  describe('user opens an image file', () => {
    beforeEach(async () => {
      await ideHelper.openFile('files/images/logo-white.png');
      await ideHelper.waitForTabToOpen('logo-white.png');
    });

    it('opens image viewer for the file', async () => {
      const viewer = await screen.findByTestId('image-viewer');
      const img = viewer.querySelector('img');

      expect(img.src).toContain('logo-white.png');
    });
  });

  describe('user opens a binary file', () => {
    beforeEach(async () => {
      await ideHelper.openFile('Gemfile.zip');
      await ideHelper.waitForTabToOpen('Gemfile.zip');
    });

    it('opens image viewer for the file', async () => {
      const downloadButton = await screen.findByText('Download');

      expect(downloadButton.getAttribute('download')).toEqual('Gemfile.zip');
      expect(downloadButton.getAttribute('href')).toContain('/raw/');
    });
  });
});
