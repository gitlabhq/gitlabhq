import htmlEventFilter from 'test_fixtures_static/event_filter.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import Activities from '~/activities';
import { InfiniteScroller } from '~/infinite_scroller';
import { setCookie } from '~/lib/utils/common_utils';

jest.mock('~/infinite_scroller');

class FakeInfiniteScroller {
  eventTarget = new EventTarget();
  initialize = jest.fn();
  destroy = jest.fn();
}

describe('Activities', () => {
  const filterIds = [
    'all_event_filter',
    'push_event_filter',
    'merged_event_filter',
    'comments_event_filter',
    'team_event_filter',
  ];

  beforeEach(() => {
    InfiniteScroller.mockImplementation((...args) => new FakeInfiniteScroller(...args));
    setHTMLFixture(`
      <div class="js-infinite-scrolling-root">
        <div class="js-infinite-scrolling-content">
          ${htmlEventFilter}
        </div>
        <div class="js-infinite-scrolling-page-end">
          <div class="js-infinite-scrolling-loading"></div>
        </div>
      </div>
    `);
    // this cookie is initially set by the server using 'set-cookie' header
    setCookie('event_filter', filterIds[0].split('_')[0]);
    // eslint-disable-next-line no-new
    new Activities();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe.each(filterIds)("when selecting tab with an id '%s'", (id) => {
    beforeEach(() => {
      document.getElementById(id).click();
    });

    it('should highlight only the active tab', () => {
      filterIds.forEach((filterId) => {
        expect(document.getElementById(filterId).parentElement.classList.contains('active')).toBe(
          id === filterId,
        );
      });
    });
  });

  it('does not activate the tab twice', () => {
    document.getElementById(filterIds[0]).click();
    document.getElementById(filterIds[0]).click();
    expect(InfiniteScroller).toHaveBeenCalledTimes(1);
  });
});
