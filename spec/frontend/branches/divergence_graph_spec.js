import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import init from '~/branches/divergence_graph';

describe('Divergence graph', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);

    mock.onGet('/-/diverging_counts').reply(200, {
      master: { ahead: 1, behind: 1 },
      'test/hello-world': { ahead: 1, behind: 1 },
    });

    jest.spyOn(axios, 'get');

    document.body.innerHTML = `
      <div class="js-branch-item" data-name="master"><div class="js-branch-divergence-graph"></div></div>
      <div class="js-branch-item" data-name="test/hello-world"><div class="js-branch-divergence-graph"></div></div>
    `;
  });

  afterEach(() => {
    mock.restore();
  });

  it('calls axos get with list of branch names', () =>
    init('/-/diverging_counts').then(() => {
      expect(axios.get).toHaveBeenCalledWith('/-/diverging_counts', {
        params: { names: ['master', 'test/hello-world'] },
      });
    }));

  it('creates Vue components', () =>
    init('/-/diverging_counts').then(() => {
      expect(document.querySelector('[data-name="master"]').innerHTML).not.toEqual('');
      expect(document.querySelector('[data-name="test/hello-world"]').innerHTML).not.toEqual('');
    }));
});
