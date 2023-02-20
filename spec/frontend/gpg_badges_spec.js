import MockAdapter from 'axios-mock-adapter';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { TEST_HOST } from 'spec/test_constants';
import GpgBadges from '~/gpg_badges';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

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
    setHTMLFixture(`
      <form
        class="commits-search-form js-signature-container" data-signatures-path="${dummyUrl}" action="${dummyUrl}"
        method="get">
        <input name="utf8" type="hidden" value="${utf8}">
        <input type="search" name="search" value="${search}" id="commits-search"class="form-control search-text-input input-short">
      </form>
      <div class="parent-container">
        <div class="js-loading-signature-badge" data-commit-sha="${dummyCommitSha}"></div>
      </div>
    `);
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    setForm();
  });

  afterEach(() => {
    mock.restore();
    resetHTMLFixture();
  });

  it('does not make a request if there is no container element', async () => {
    setHTMLFixture('');
    jest.spyOn(axios, 'get').mockImplementation(() => {});

    await GpgBadges.fetch();
    expect(axios.get).not.toHaveBeenCalled();
    resetHTMLFixture();
  });

  it('throws an error if the endpoint is missing', async () => {
    setHTMLFixture('<div class="js-signature-container"></div>');
    jest.spyOn(axios, 'get').mockImplementation(() => {});

    await expect(GpgBadges.fetch()).rejects.toEqual(
      new Error('Missing commit signatures endpoint!'),
    );
    expect(axios.get).not.toHaveBeenCalled();
    resetHTMLFixture();
  });

  it('fetches commit signatures', async () => {
    mock.onGet(dummyUrl).replyOnce(HTTP_STATUS_OK);

    await GpgBadges.fetch();

    expect(mock.history.get).toHaveLength(1);
    expect(mock.history.get[0]).toMatchObject({
      params: { search: '', utf8: '✓' },
      url: dummyUrl,
    });
  });

  it('fetches commit signatures with search parameters with spaces', async () => {
    mock.onGet(dummyUrl).replyOnce(HTTP_STATUS_OK);
    setForm({ search: 'my search' });

    await GpgBadges.fetch();

    expect(mock.history.get).toHaveLength(1);
    expect(mock.history.get[0]).toMatchObject({
      params: { search: 'my search', utf8: '✓' },
      url: dummyUrl,
    });
  });

  it('fetches commit signatures with search parameters with plus symbols', async () => {
    mock.onGet(dummyUrl).replyOnce(HTTP_STATUS_OK);
    setForm({ search: 'my+search' });

    await GpgBadges.fetch();

    expect(mock.history.get).toHaveLength(1);
    expect(mock.history.get[0]).toMatchObject({
      params: { search: 'my+search', utf8: '✓' },
      url: dummyUrl,
    });
  });

  it('displays a loading spinner', async () => {
    mock.onGet(dummyUrl).replyOnce(HTTP_STATUS_OK);

    await GpgBadges.fetch();
    expect(document.querySelector('.js-loading-signature-badge:empty')).toBe(null);
    const spinners = document.querySelectorAll('.js-loading-signature-badge span.gl-spinner');

    expect(spinners.length).toBe(1);
  });

  it('replaces the loading spinner', async () => {
    mock.onGet(dummyUrl).replyOnce(HTTP_STATUS_OK, dummyResponse);

    await GpgBadges.fetch();
    expect(document.querySelector('.js-loading-signature-badge')).toBe(null);
    const parentContainer = document.querySelector('.parent-container');

    expect(parentContainer.innerHTML.trim()).toEqual(dummyBadgeHtml);
  });
});
