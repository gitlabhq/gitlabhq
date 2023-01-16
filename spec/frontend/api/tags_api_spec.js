import MockAdapter from 'axios-mock-adapter';
import * as tagsApi from '~/api/tags_api';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('~/api/tags_api.js', () => {
  let mock;
  let originalGon;

  const projectId = 1;

  beforeEach(() => {
    mock = new MockAdapter(axios);

    originalGon = window.gon;
    window.gon = { api_version: 'v7' };
  });

  afterEach(() => {
    mock.restore();
    window.gon = originalGon;
  });

  describe('getTag', () => {
    it('fetches a tag of a given tag name of a particular project', () => {
      const tagName = 'tag-name';
      const expectedUrl = `/api/v7/projects/${projectId}/repository/tags/${tagName}`;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, {
        name: tagName,
      });

      return tagsApi.getTag(projectId, tagName).then(({ data }) => {
        expect(data.name).toBe(tagName);
      });
    });
  });
});
