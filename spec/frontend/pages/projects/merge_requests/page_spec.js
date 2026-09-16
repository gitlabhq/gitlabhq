import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import initMrNotes from 'ee_else_ce/mr_notes';
import { initMrPage } from '~/pages/projects/merge_requests/page';
import diffsEventHub from '~/diffs/event_hub';
import { EVT_MR_DIFF_GENERATED, EVT_MR_PREPARED } from '~/diffs/constants';

jest.mock('ee_else_ce/mr_notes', () => jest.fn());
jest.mock('~/pages/projects/merge_requests/init_merge_request_show', () => jest.fn());
jest.mock('~/mr_more_dropdown', () => ({ initMrMoreDropdown: jest.fn() }));
jest.mock('~/code_review/signals', () => ({ start: jest.fn() }));
jest.mock('~/sidebar/sidebar_bundle', () => jest.fn());

describe('pages/projects/merge_requests/page', () => {
  useMockLocationHelper();

  beforeEach(() => {
    setHTMLFixture(`
      <span class="js-commits-count">-</span>
      <span class="js-changes-tab-count" data-gid="gid://gitlab/MergeRequest/1">-</span>
    `);
  });

  afterEach(() => {
    resetHTMLFixture();
    diffsEventHub.$off(EVT_MR_DIFF_GENERATED);
    diffsEventHub.$off(EVT_MR_PREPARED);
  });

  describe('EVT_MR_DIFF_GENERATED handler', () => {
    beforeEach(() => {
      initMrPage(false);
    });

    it('updates the commits count badge from - to the real count', () => {
      diffsEventHub.$emit(EVT_MR_DIFF_GENERATED, {
        commitCount: 4,
        diffStatsSummary: { fileCount: 2 },
      });

      expect(document.querySelector('.js-commits-count').textContent).toBe('4');
    });

    it('updates the changes count badge from - to the real count', () => {
      diffsEventHub.$emit(EVT_MR_DIFF_GENERATED, {
        commitCount: 4,
        diffStatsSummary: { fileCount: 2 },
      });

      expect(document.querySelector('.js-changes-tab-count').textContent).toBe('2');
    });

    it('does not overwrite the commits count if it is already set', () => {
      document.querySelector('.js-commits-count').textContent = '3';

      diffsEventHub.$emit(EVT_MR_DIFF_GENERATED, {
        commitCount: 4,
        diffStatsSummary: { fileCount: 2 },
      });

      expect(document.querySelector('.js-commits-count').textContent).toBe('3');
    });

    it('does not update the commits count when commitCount is null', () => {
      diffsEventHub.$emit(EVT_MR_DIFF_GENERATED, {
        commitCount: null,
        diffStatsSummary: { fileCount: 2 },
      });

      expect(document.querySelector('.js-commits-count').textContent).toBe('-');
    });

    it('does not overwrite the changes count if it is already set', () => {
      document.querySelector('.js-changes-tab-count').textContent = '7';

      diffsEventHub.$emit(EVT_MR_DIFF_GENERATED, {
        commitCount: 4,
        diffStatsSummary: { fileCount: 2 },
      });

      expect(document.querySelector('.js-changes-tab-count').textContent).toBe('7');
    });

    it('does not update the changes count when fileCount is null', () => {
      diffsEventHub.$emit(EVT_MR_DIFF_GENERATED, {
        commitCount: 4,
        diffStatsSummary: { fileCount: null },
      });

      expect(document.querySelector('.js-changes-tab-count').textContent).toBe('-');
    });
  });

  describe('EVT_MR_PREPARED handler', () => {
    const createRapidDiffsApp = () => ({});
    let getCurrentAction;

    beforeEach(() => {
      getCurrentAction = jest.fn().mockReturnValue('diffs');
      initMrNotes.mockReturnValue({
        tabs: { getCurrentAction, isDiffAction: (action) => action === 'diffs' },
      });
    });

    it('reloads the page when the Changes tab is the current tab', () => {
      initMrPage(createRapidDiffsApp);

      diffsEventHub.$emit(EVT_MR_PREPARED);

      expect(window.location.reload).toHaveBeenCalledTimes(1);
    });

    it('does not reload the page from another tab', () => {
      getCurrentAction.mockReturnValue('show');
      initMrPage(createRapidDiffsApp);

      diffsEventHub.$emit(EVT_MR_PREPARED);

      expect(window.location.reload).not.toHaveBeenCalled();
    });

    it('does not reload the page without Rapid Diffs', () => {
      initMrPage(false);

      diffsEventHub.$emit(EVT_MR_PREPARED);

      expect(window.location.reload).not.toHaveBeenCalled();
    });
  });
});
