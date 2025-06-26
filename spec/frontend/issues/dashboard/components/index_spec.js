import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { mountIssuesDashboardApp } from '~/issues/dashboard';

describe('IssueDashboardRoot', () => {
  beforeEach(() => {
    setHTMLFixture(
      '<div class="js-issues-dashboard" data-has-issue-date-filter-feature="true"></div>',
    );
    // eslint-disable-next-line no-console
    console.warn = jest.fn();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('mounts without errors and vue warnings', async () => {
    await expect(mountIssuesDashboardApp()).resolves.toBeTruthy();
  });
});
