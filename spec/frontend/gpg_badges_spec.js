import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'spec/test_constants';
import GpgBadges from '~/gpg_badges';
import axios from '~/lib/utils/axios_utils';

describe('GpgBadges', () => {
  let mock;
  const dummyCommitSha = 'n0m0rec0ffee';
  const dummyBadgeHtml = 'dummy html';
  const dummyResponse = {
    signatures: [
      {
        commit_sha: dummyCommitSha,
        html: dummyBadgeHtml,
      },
    ],
  };
  const dummyUrl = `${TEST_HOST}/dummy/signatures`;

  const setForm = ({ utf8 = '✓', search = '' } = {}) => {
    setFixtures(`
      <form
        class="commits-search-form js-signature-container" data-signatures-path="${dummyUrl}" action="${dummyUrl}"
        method="get">
        <input name="utf8" type="hidden" value="${utf8}">
        <input type="search" name="search" value="${search}" id="commits-search"class="form-control search-text-input input-short">
      </form>
      <div class="parent-container">
        <div class="js-loading-gpg-badge" data-commit-sha="${dummyCommitSha}"></div>
      </div>
    `);
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    setForm();
  });

  afterEach(() => {
    mock.restore();
  });

  it('does not make a request if there is no container element', (done) => {
    setFixtures('');
    jest.spyOn(axios, 'get').mockImplementation(() => {});

    GpgBadges.fetch()
      .then(() => {
        expect(axios.get).not.toHaveBeenCalled();
      })
      .then(done)
      .catch(done.fail);
  });

  it('throws an error if the endpoint is missing', (done) => {
    setFixtures('<div class="js-signature-container"></div>');
    jest.spyOn(axios, 'get').mockImplementation(() => {});

    GpgBadges.fetch()
      .then(() => done.fail('Expected error to be thrown'))
      .catch((error) => {
        expect(error.message).toBe('Missing commit signatures endpoint!');
        expect(axios.get).not.toHaveBeenCalled();
      })
      .then(done)
      .catch(done.fail);
  });

  it('fetches commit signatures', async () => {
    mock.onGet(dummyUrl).replyOnce(200);

    await GpgBadges.fetch();

    expect(mock.history.get).toHaveLength(1);
    expect(mock.history.get[0]).toMatchObject({
      params: { search: '', utf8: '✓' },
      url: dummyUrl,
    });
  });

  it('fetches commit signatures with search parameters with spaces', async () => {
    mock.onGet(dummyUrl).replyOnce(200);
    setForm({ search: 'my search' });

    await GpgBadges.fetch();

    expect(mock.history.get).toHaveLength(1);
    expect(mock.history.get[0]).toMatchObject({
      params: { search: 'my search', utf8: '✓' },
      url: dummyUrl,
    });
  });

  it('fetches commit signatures with search parameters with plus symbols', async () => {
    mock.onGet(dummyUrl).replyOnce(200);
    setForm({ search: 'my+search' });

    await GpgBadges.fetch();

    expect(mock.history.get).toHaveLength(1);
    expect(mock.history.get[0]).toMatchObject({
      params: { search: 'my+search', utf8: '✓' },
      url: dummyUrl,
    });
  });

  it('displays a loading spinner', (done) => {
    mock.onGet(dummyUrl).replyOnce(200);

    GpgBadges.fetch()
      .then(() => {
        expect(document.querySelector('.js-loading-gpg-badge:empty')).toBe(null);
        const spinners = document.querySelectorAll('.js-loading-gpg-badge span.gl-spinner');

        expect(spinners.length).toBe(1);
        done();
      })
      .catch(done.fail);
  });

  it('replaces the loading spinner', (done) => {
    mock.onGet(dummyUrl).replyOnce(200, dummyResponse);

    GpgBadges.fetch()
      .then(() => {
        expect(document.querySelector('.js-loading-gpg-badge')).toBe(null);
        const parentContainer = document.querySelector('.parent-container');

        expect(parentContainer.innerHTML.trim()).toEqual(dummyBadgeHtml);
        done();
      })
      .catch(done.fail);
  });
});
