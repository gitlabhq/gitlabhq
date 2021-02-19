import initTabs from '~/admin/users/tabs';
import Api from '~/api';

jest.mock('~/api.js');
jest.mock('~/lib/utils/common_utils');

describe('tabs', () => {
  beforeEach(() => {
    setFixtures(`
    <div>
      <div class="js-users-tab-item">
        <a href="#users" data-testid='users-tab'>Users</a>
      </div>
      <div class="js-users-tab-item">
        <a href="#cohorts" data-testid='cohorts-tab'>Cohorts</a>
      </div>
    </div`);

    initTabs();
  });

  afterEach(() => {});

  describe('tracking', () => {
    it('tracks event when cohorts tab is clicked', () => {
      document.querySelector('[data-testid="cohorts-tab"]').click();

      expect(Api.trackRedisHllUserEvent).toHaveBeenCalledWith('i_analytics_cohorts');
    });

    it('does not track an event when users tab is clicked', () => {
      document.querySelector('[data-testid="users-tab"]').click();

      expect(Api.trackRedisHllUserEvent).not.toHaveBeenCalled();
    });
  });
});
