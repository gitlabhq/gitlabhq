import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { fetchReadme } from '~/repository/graphql';

describe('fetchReadme', () => {
  let mock;
  const url = '/group/project/-/blob/main/README.txt';

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  it('requests the rich viewer as JSON and returns the rendered html', async () => {
    mock.onGet(url).reply(HTTP_STATUS_OK, { html: '<p>Hello</p>', path: 'README.md' });

    const result = await fetchReadme(url);

    expect(mock.history.get[0].params).toEqual({ format: 'json', viewer: 'rich' });
    expect(result).toEqual({ html: '<p>Hello</p>', path: 'README.md', __typename: 'ReadmeFile' });
  });

  it('returns a null html field when the blob has no rich viewer', async () => {
    mock.onGet(url).reply(HTTP_STATUS_OK, { path: 'README.txt', rich_viewer: null });

    const result = await fetchReadme(url);

    expect(result).toEqual({
      html: null,
      path: 'README.txt',
      rich_viewer: null,
      __typename: 'ReadmeFile',
    });
  });
});
