import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import refreshCounts from '~/pages/search/show/refresh_counts';

const URL = `${TEST_HOST}/search/count?search=lorem+ipsum&project_id=3`;
const urlWithScope = (scope) => `${URL}&scope=${scope}`;
const counts = [
  { scope: 'issues', count: 4 },
  { scope: 'merge_requests', count: 5 },
];
const fixture = `<div class="badge">22</div>
<div class="badge js-search-count hidden" data-url="${urlWithScope('issues')}"></div>
<div class="badge js-search-count hidden" data-url="${urlWithScope('merge_requests')}"></div>`;

describe('pages/search/show/refresh_counts', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    setFixtures(fixture);
  });

  afterEach(() => {
    mock.restore();
  });

  it('fetches and displays search counts', () => {
    counts.forEach(({ scope, count }) => {
      mock.onGet(urlWithScope(scope)).reply(200, { count });
    });

    // assert before act behavior
    return refreshCounts().then(() => {
      expect(document.body.innerHTML).toMatchSnapshot();
    });
  });
});
