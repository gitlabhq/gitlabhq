import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import BuildArtifacts from '~/build_artifacts';
import { visitUrl } from '~/lib/utils/url_utility';
import { hide, initTooltips, show } from '~/tooltips';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
}));

jest.mock('~/tooltips', () => ({
  initTooltips: jest.fn(),
  show: jest.fn(),
  hide: jest.fn(),
}));

describe('BuildArtifacts', () => {
  const directoryPath = '/project/-/jobs/1/artifacts/browse/logs';
  const filePath = '/project/-/jobs/1/artifacts/file/logs/app.log';
  const externalFilePath = '/project/-/jobs/1/artifacts/external_file/logs/external.log';

  const findTreeHolder = () => document.querySelector('.tree-holder');
  const findDirectoryRow = () => document.querySelector('.tree-item:not(.js-artifact-tree-row)');
  const findFileRow = () =>
    document.querySelector('.js-artifact-tree-row[data-external-link="false"]');
  const findExternalRow = () =>
    document.querySelector('.js-artifact-tree-row[data-external-link="true"]');
  const findTopBlockDownload = () => document.querySelector('.top-block .download');
  const findRowDownloadButton = (row) => row.querySelector('.gl-button');

  const setupFixture = () => {
    setHTMLFixture(`
      <div class="top-block">
        <a href="#" class="download" rel="nofollow" download="">Download artifacts archive</a>
      </div>
      <div class="tree-holder">
        <table class="table tree-table">
          <tr class="tree-item" data-link="${directoryPath}">
            <td class="tree-item-file-name">
              <a href="#" class="str-truncated">
                <span>logs</span>
              </a>
            </td>
            <td></td>
            <td></td>
          </tr>
          <tr class="tree-item js-artifact-tree-row" data-link="${filePath}" data-external-link="false">
            <td class="tree-item-file-name">
              <a href="#" class="str-truncated">
                <span>app.log</span>
              </a>
            </td>
            <td>54 KB</td>
            <td>
              <a href="#" class="gl-button" aria-label="Download" download="app.log">↓</a>
            </td>
          </tr>
          <tr class="tree-item js-artifact-tree-row" data-link="${externalFilePath}" data-external-link="true">
            <td class="tree-item-file-name">
              <a href="#" class="tree-item-file-external-link js-artifact-tree-tooltip str-truncated">
                <span>external.log</span>
              </a>
            </td>
            <td>54 KB</td>
            <td>
              <a href="#" class="gl-button" aria-label="Download" download="external.log">↓</a>
            </td>
          </tr>
        </table>
      </div>
    `);
  };

  let bodyClickListener;

  beforeEach(() => {
    setupFixture();
    // eslint-disable-next-line no-new
    new BuildArtifacts();

    bodyClickListener = jest.fn();
    document.body.addEventListener('click', bodyClickListener);
  });

  afterEach(() => {
    document.body.removeEventListener('click', bodyClickListener);
    resetHTMLFixture();
  });

  describe('setupEntryClick', () => {
    it('navigates to the row data-link when a non-link cell is clicked', () => {
      findFileRow().querySelector('td:nth-child(2)').click();

      expect(visitUrl).toHaveBeenCalledWith(filePath, false);
    });

    it('parses data-external-link as a boolean', () => {
      findExternalRow().querySelector('td:nth-child(2)').click();

      expect(visitUrl).toHaveBeenCalledWith(externalFilePath, true);
    });

    it('navigates directory rows that have no data-external-link attribute', () => {
      findDirectoryRow().querySelector('.tree-item-file-name').click();

      expect(visitUrl).toHaveBeenCalledWith(directoryPath, false);
    });

    it('does not navigate when the click misses every data-link row', () => {
      findTreeHolder().click();

      expect(visitUrl).not.toHaveBeenCalled();
    });
  });

  describe('disablePropagation', () => {
    it('blocks row navigation when a link inside a row is clicked', () => {
      findRowDownloadButton(findFileRow()).click();

      expect(visitUrl).not.toHaveBeenCalled();
    });

    it('blocks row navigation when an element inside a row link is clicked', () => {
      findExternalRow().querySelector('.js-artifact-tree-tooltip span').click();

      expect(visitUrl).not.toHaveBeenCalled();
    });

    it('stops .top-block .download clicks from bubbling past .top-block', () => {
      findTopBlockDownload().click();

      expect(bodyClickListener).not.toHaveBeenCalled();
    });
  });

  describe('setupTooltips', () => {
    it('initializes tooltips with manual trigger and bottom placement', () => {
      expect(initTooltips).toHaveBeenCalledWith({
        placement: 'bottom',
        trigger: 'manual',
      });
    });

    it('shows the tooltip anchor on row mouseenter', () => {
      const row = findExternalRow();
      const tooltip = row.querySelector('.js-artifact-tree-tooltip');

      row.dispatchEvent(new MouseEvent('mouseenter'));

      expect(show).toHaveBeenCalledWith(tooltip);
    });

    it('hides the tooltip anchor on row mouseleave', () => {
      const row = findExternalRow();
      const tooltip = row.querySelector('.js-artifact-tree-tooltip');

      row.dispatchEvent(new MouseEvent('mouseleave'));

      expect(hide).toHaveBeenCalledWith(tooltip);
    });

    it('does not bind hover handlers to directory rows', () => {
      findDirectoryRow().dispatchEvent(new MouseEvent('mouseenter'));

      expect(show).not.toHaveBeenCalled();
    });
  });

  describe('without a tree holder', () => {
    beforeEach(() => {
      resetHTMLFixture();
      setHTMLFixture('<div></div>');
    });

    it('does not throw', () => {
      expect(() => new BuildArtifacts()).not.toThrow();
    });
  });
});
