import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import {
  fetchRefs,
  fetchMostRecentlyUpdated,
} from '~/security_configuration/security_attributes/api/refs_api';
import { createMockRestApiRef } from '../../mock_data';

const PROJECT_PATH = 'gitlab-org/gitlab';

describe('Refs API', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  const mockRefsResponse = (branches = [], tags = []) => {
    mock.onGet(/\/repository\/branches/).reply(HTTP_STATUS_OK, branches);
    mock.onGet(/\/repository\/tags/).reply(HTTP_STATUS_OK, tags);
  };

  const findRequest = ({ type }) => mock.history.get.find((req) => req.url.includes(type));

  describe('fetchRefs', () => {
    it('fetches, transforms, and combines branches and tags', async () => {
      const mockBranches = [createMockRestApiRef()];
      const mockTags = [createMockRestApiRef({ name: 'v1.0.0', protected: false })];

      mockRefsResponse(mockBranches, mockTags);

      const result = await fetchRefs(PROJECT_PATH, { limit: 10 });

      expect(result).toHaveLength(2);
      expect(result[0]).toMatchObject({
        id: 'branch-main',
        name: 'main',
        refType: 'BRANCH',
        isProtected: true,
      });
      expect(result[1]).toMatchObject({
        id: 'tag-v1.0.0',
        name: 'v1.0.0',
        refType: 'TAG',
        isProtected: false,
      });
    });

    it('fetches branches and tags with correct parameters', async () => {
      const mockBranches = [createMockRestApiRef()];
      const mockTags = [createMockRestApiRef({ name: 'v1.0.0', protected: false })];

      mockRefsResponse(mockBranches, mockTags);

      await fetchRefs(PROJECT_PATH, { search: 'test', limit: 10 });

      expect(findRequest({ type: 'branches' }).params).toMatchObject({
        search: 'test',
        sort: 'updated_desc',
        per_page: 15,
      });

      expect(findRequest({ type: 'tags' }).params).toMatchObject({
        search: 'test',
        order_by: 'updated',
        sort: 'desc',
        per_page: 15,
      });
    });

    it('uses default parameters when not provided', async () => {
      mockRefsResponse();

      await fetchRefs(PROJECT_PATH);

      expect(findRequest({ type: 'branches' }).params).toMatchObject({
        search: '',
        sort: 'updated_desc',
        per_page: 15,
      });

      expect(findRequest({ type: 'tags' }).params).toMatchObject({
        search: '',
        order_by: 'updated',
        sort: 'desc',
        per_page: 15,
      });
    });

    it('respects the limit parameter', async () => {
      const mockBranches = [createMockRestApiRef(), createMockRestApiRef()];

      mockRefsResponse(mockBranches);

      const result = await fetchRefs(PROJECT_PATH, { limit: 1 });

      expect(result).toHaveLength(1);
      expect(result[0].name).toBe('main');
    });

    it('throws error if requests fail', async () => {
      mock.onGet(/\/repository\/branches/).networkError();

      await expect(fetchRefs(PROJECT_PATH)).rejects.toThrow();
    });
  });

  describe('fetchMostRecentlyUpdated', () => {
    it('fetches, transforms, combines and sorts branches and tags by commit date', async () => {
      const mockBranches = [
        createMockRestApiRef({
          name: 'develop',
          protected: false,
          commit: {
            id: 'def456',
            committed_date: '2024-11-03T10:00:00Z',
          },
        }),
      ];
      const mockTags = [
        createMockRestApiRef({
          name: 'v1.0.0',
          protected: false,
          commit: {
            id: 'abc123',
            committed_date: '2024-11-05T10:00:00Z',
          },
        }),
      ];

      mockRefsResponse(mockBranches, mockTags);

      const result = await fetchMostRecentlyUpdated(PROJECT_PATH, { limit: 10 });

      expect(result).toHaveLength(2);
      expect(result).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            name: 'v1.0.0',
            refType: 'TAG',
          }),
          expect.objectContaining({
            name: 'develop',
            refType: 'BRANCH',
          }),
        ]),
      );
    });

    it('sorts multiple refs by most recent commit date', async () => {
      const mockBranches = [
        createMockRestApiRef({ commit: { committed_date: '2024-11-06T10:00:00Z' } }),
        createMockRestApiRef({
          name: 'develop',
          commit: { committed_date: '2024-11-04T10:00:00Z' },
        }),
      ];
      const mockTags = [
        createMockRestApiRef({
          name: 'v2.0.0',
          protected: false,
          commit: {
            committed_date: '2024-11-05T10:00:00Z',
          },
        }),
        createMockRestApiRef({
          name: 'v1.0.0',
          protected: false,
          commit: {
            committed_date: '2024-11-01T10:00:00Z',
          },
        }),
      ];

      mockRefsResponse(mockBranches, mockTags);

      const result = await fetchMostRecentlyUpdated(PROJECT_PATH, { limit: 10 });

      expect(result).toHaveLength(4);
      expect(result[0].name).toBe('main'); // 2024-11-06
      expect(result[1].name).toBe('v2.0.0'); // 2024-11-05
      expect(result[2].name).toBe('develop'); // 2024-11-04
      expect(result[3].name).toBe('v1.0.0'); // 2024-11-01
    });

    it('respects the limit parameter after sorting', async () => {
      const mockBranches = [
        createMockRestApiRef({ name: 'main', commit: { committed_date: '2024-11-06T10:00:00Z' } }),
        createMockRestApiRef({
          name: 'develop',
          commit: {
            committed_date: '2024-11-03T10:00:00Z',
          },
        }),
      ];

      mockRefsResponse(mockBranches);

      const result = await fetchMostRecentlyUpdated(PROJECT_PATH, { limit: 1 });

      expect(result).toHaveLength(1);
      expect(result[0].name).toBe('main');
    });

    it('throws error if requests fail', async () => {
      mock.onGet(/\/repository\/branches/).networkError();

      await expect(fetchMostRecentlyUpdated(PROJECT_PATH)).rejects.toThrow();
    });
  });

  it('passes a given abort signal to axios requests', async () => {
    const projectPath = 'gitlab-org/gitlab';
    const abortController = new AbortController();

    mock.onGet(/\/repository\/branches/).reply(HTTP_STATUS_OK, []);
    mock.onGet(/\/repository\/tags/).reply(HTTP_STATUS_OK, []);

    await fetchRefs(projectPath, { limit: 10 }, abortController.signal);

    const branchRequest = mock.history.get.find((req) => req.url.includes('branches'));
    const tagRequest = mock.history.get.find((req) => req.url.includes('tags'));

    expect(branchRequest.signal).toBe(abortController.signal);
    expect(tagRequest.signal).toBe(abortController.signal);
  });
});
