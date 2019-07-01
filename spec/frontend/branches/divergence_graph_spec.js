import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import init from '~/branches/divergence_graph';

describe('Divergence graph', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);

    mock.onGet('/-/diverging_counts').reply(200, {
      master: { ahead: 1, behind: 1 },
    });

    jest.spyOn(axios, 'get');

    document.body.innerHTML = `
      <div class="js-branch-item" data-name="master"></div>
    `;
  });

  afterEach(() => {
    mock.restore();
  });

  it('calls axos get with list of branch names', () =>
    init('/-/diverging_counts').then(() => {
      expect(axios.get).toHaveBeenCalledWith('/-/diverging_counts', {
        params: { names: ['master'] },
      });
    }));
});
