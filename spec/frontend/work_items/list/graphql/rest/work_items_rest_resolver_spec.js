import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import { workItemsRestResolver } from '~/work_items/list/graphql/rest/work_items_rest_resolver';

const FULL_PATH = 'gitlab-org/gitlab-shell';
const ENCODED_PATH = encodeURIComponent(FULL_PATH);
const ENDPOINT = `/api/v4/namespaces/${ENCODED_PATH}/-/work_items`;

const makeNamespace = (
  fullPath = FULL_PATH,
  id = 'gid://gitlab/Namespaces::ProjectNamespace/26',
) => ({
  id,
  fullPath,
  name: 'Gitlab Shell',
  __typename: 'Namespace',
});

const makeRestItem = (overrides = {}) => ({
  global_id: 'gid://gitlab/WorkItem/1',
  iid: 42,
  title: 'My work item',
  state: 'opened',
  created_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-02T00:00:00Z',
  closed_at: null,
  reference: 'gitlab-org/gitlab-shell#42',
  web_path: '/gitlab-org/gitlab-shell/-/work_items/42',
  author: {
    id: 1,
    name: 'Administrator',
    username: 'root',
    avatar_url: 'http://localhost/avatar.png',
    web_path: '/root',
  },
  namespace: {
    id: 10,
    full_path: FULL_PATH,
  },
  work_item_type: {
    id: 5,
    name: 'Issue',
    icon_name: 'issue-type-issue',
  },
  features: null,
  ...overrides,
});

describe('workItemsRestResolver', () => {
  let mockAxios;

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    window.gon = { api_version: 'v4' };
  });

  afterEach(() => {
    mockAxios.restore();
    delete window.gon;
  });

  describe('happy path', () => {
    it('fetches from the correct URL and returns a WorkItemConnection shape', async () => {
      const item = makeRestItem();
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [item], {});

      const result = await workItemsRestResolver(makeNamespace(), {});

      expect(result).toMatchObject({ __typename: 'WorkItemConnection' });
      expect(result.nodes).toHaveLength(1);
    });

    it('URL-encodes the fullPath when building the endpoint', async () => {
      const slashPath = 'my-group/my-project';
      const encodedSlashPath = encodeURIComponent(slashPath);
      mockAxios
        .onGet(`/api/v4/namespaces/${encodedSlashPath}/-/work_items`)
        .reply(HTTP_STATUS_OK, [], {});

      await workItemsRestResolver(makeNamespace(slashPath), {});

      expect(mockAxios.history.get).toHaveLength(1);
      expect(mockAxios.history.get[0].url).toContain(encodedSlashPath);
    });

    it('maps REST item fields to the GraphQL WorkItem shape', async () => {
      const item = makeRestItem();
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [item], {});

      const { nodes } = await workItemsRestResolver(makeNamespace(), {});
      const node = nodes[0];

      expect(node).toMatchObject({ __typename: 'WorkItem' });
      expect(node.id).toBe(item.global_id);
      expect(node.iid).toBe(String(item.iid));
      expect(node.title).toBe(item.title);
      expect(node.state).toBe('OPEN');
      expect(node.createdAt).toBe(item.created_at);
      expect(node.updatedAt).toBe(item.updated_at);
      expect(node.closedAt).toBeNull();
      expect(node.webPath).toBe(item.web_path);
    });

    it('maps confidential field with default value of false', async () => {
      const item = makeRestItem();
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [item], {});

      const { nodes } = await workItemsRestResolver(makeNamespace(), {});

      expect(nodes[0].confidential).toBe(false);
    });

    it('maps confidential field when true', async () => {
      const item = makeRestItem({ confidential: true });
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [item], {});

      const { nodes } = await workItemsRestResolver(makeNamespace(), {});

      expect(nodes[0].confidential).toBe(true);
    });

    it('maps hidden field with default value of false', async () => {
      const item = makeRestItem();
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [item], {});

      const { nodes } = await workItemsRestResolver(makeNamespace(), {});

      expect(nodes[0].hidden).toBe(false);
    });

    it('maps hidden field when true', async () => {
      const item = makeRestItem({ hidden: true });
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [item], {});

      const { nodes } = await workItemsRestResolver(makeNamespace(), {});

      expect(nodes[0].hidden).toBe(true);
    });

    it('maps author to UserCore shape', async () => {
      const item = makeRestItem();
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [item], {});

      const { nodes } = await workItemsRestResolver(makeNamespace(), {});
      const { author } = nodes[0];

      expect(author).toMatchObject({ __typename: 'UserCore' });
      expect(author.id).toBe(`gid://gitlab/User/${item.author.id}`);
      expect(author.name).toBe(item.author.name);
      expect(author.username).toBe(item.author.username);
    });

    it('maps namespace from resolver context to Namespace shape', async () => {
      const item = makeRestItem();
      const testNamespace = makeNamespace(
        'test-org/test-project',
        'gid://gitlab/Namespaces::ProjectNamespace/99',
      );
      const testEndpoint = `/api/v4/namespaces/${encodeURIComponent('test-org/test-project')}/-/work_items`;
      mockAxios.onGet(testEndpoint).reply(HTTP_STATUS_OK, [item], {});

      const { nodes } = await workItemsRestResolver(testNamespace, {});
      const { namespace } = nodes[0];

      expect(namespace).toMatchObject({
        __typename: 'Namespace',
        id: 'gid://gitlab/Namespaces::ProjectNamespace/99',
        fullPath: 'test-org/test-project',
      });
    });

    it('maps workItemType to WorkItemType shape', async () => {
      const item = makeRestItem();
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [item], {});

      const { nodes } = await workItemsRestResolver(makeNamespace(), {});
      const { workItemType } = nodes[0];

      expect(workItemType).toMatchObject({ __typename: 'WorkItemType' });
      expect(workItemType.id).toBe(`gid://gitlab/WorkItems::Type/${item.work_item_type.id}`);
      expect(workItemType.name).toBe(item.work_item_type.name);
      expect(workItemType.iconName).toBe(item.work_item_type.icon_name);
    });

    it('returns an empty nodes array when response data is empty', async () => {
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [], {});

      const { nodes } = await workItemsRestResolver(makeNamespace(), {});

      expect(nodes).toEqual([]);
    });
  });

  describe('pagination', () => {
    it('sets hasNextPage and endCursor from x-next-cursor header', async () => {
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [], { 'x-next-cursor': 'cursor_abc' });

      const { pageInfo } = await workItemsRestResolver(makeNamespace(), {});

      expect(pageInfo).toMatchObject({ __typename: 'PageInfo' });
      expect(pageInfo.hasNextPage).toBe(true);
      expect(pageInfo.endCursor).toBe('cursor_abc');
    });

    it('sets hasPreviousPage and startCursor from x-prev-cursor header', async () => {
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [], { 'x-prev-cursor': 'cursor_xyz' });

      const { pageInfo } = await workItemsRestResolver(makeNamespace(), {});

      expect(pageInfo.hasPreviousPage).toBe(true);
      expect(pageInfo.startCursor).toBe('cursor_xyz');
    });

    it('sets hasNextPage and hasPreviousPage to false when cursor headers are absent', async () => {
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [], {});

      const { pageInfo } = await workItemsRestResolver(makeNamespace(), {});

      expect(pageInfo.hasNextPage).toBe(false);
      expect(pageInfo.hasPreviousPage).toBe(false);
      expect(pageInfo.endCursor).toBeNull();
      expect(pageInfo.startCursor).toBeNull();
    });
  });

  describe('LABELS widget mapping', () => {
    it('maps labels from features.labels to the LABELS widget', async () => {
      const item = makeRestItem({
        features: {
          labels: {
            allows_scoped_labels: true,
            labels: [
              {
                id: 10,
                title: 'bug',
                color: '#e11',
                text_color: '#fff',
                description: 'A bug',
              },
            ],
          },
        },
      });
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [item], {});

      const { nodes } = await workItemsRestResolver(makeNamespace(), {});
      const labelsWidget = nodes[0].widgets.find((w) => w.type === 'LABELS');

      expect(labelsWidget).toMatchObject({ __typename: 'WorkItemWidgetLabels' });
      expect(labelsWidget.allowsScopedLabels).toBe(true);
      expect(labelsWidget.labels.nodes).toHaveLength(1);
      expect(labelsWidget.labels.nodes[0]).toMatchObject({
        __typename: 'Label',
        id: 'gid://gitlab/Label/10',
        title: 'bug',
        color: '#e11',
        textColor: '#fff',
        description: 'A bug',
      });
    });
  });

  describe('ASSIGNEES widget mapping', () => {
    it('returns an empty assignees array when features is null', async () => {
      const item = makeRestItem({ features: null });
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [item], {});

      const { nodes } = await workItemsRestResolver(makeNamespace(), {});
      const assigneesWidget = nodes[0].widgets.find((w) => w.type === 'ASSIGNEES');

      expect(assigneesWidget).toMatchObject({ __typename: 'WorkItemWidgetAssignees' });
      expect(assigneesWidget.assignees.nodes).toEqual([]);
    });

    it('returns an empty assignees array when features.assignees is undefined', async () => {
      const item = makeRestItem({ features: {} });
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [item], {});

      const { nodes } = await workItemsRestResolver(makeNamespace(), {});
      const assigneesWidget = nodes[0].widgets.find((w) => w.type === 'ASSIGNEES');

      expect(assigneesWidget.assignees.nodes).toEqual([]);
    });

    it('maps assignees from features.assignees to UserCore nodes', async () => {
      const item = makeRestItem({
        features: {
          assignees: [
            {
              id: 100,
              name: 'John Doe',
              username: 'jdoe',
              avatar_url: 'https://example.com/avatar.png',
              web_url: 'https://gitlab.example.com/jdoe',
              web_path: '/jdoe',
            },
          ],
        },
      });
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [item], {});

      const { nodes } = await workItemsRestResolver(makeNamespace(), {});
      const assigneesWidget = nodes[0].widgets.find((w) => w.type === 'ASSIGNEES');

      expect(assigneesWidget.assignees.nodes).toHaveLength(1);
      expect(assigneesWidget.assignees.nodes[0]).toMatchObject({
        __typename: 'UserCore',
        id: 'gid://gitlab/User/100',
        name: 'John Doe',
        username: 'jdoe',
        avatarUrl: 'https://example.com/avatar.png',
        webUrl: 'https://gitlab.example.com/jdoe',
        webPath: '/jdoe',
      });
    });

    it('handles multiple assignees correctly', async () => {
      const item = makeRestItem({
        features: {
          assignees: [
            {
              id: 100,
              name: 'John Doe',
              username: 'jdoe',
              avatar_url: 'https://example.com/avatar1.png',
              web_url: 'https://gitlab.example.com/jdoe',
              web_path: '/jdoe',
            },
            {
              id: 101,
              name: 'Jane Smith',
              username: 'jsmith',
              avatar_url: 'https://example.com/avatar2.png',
              web_url: 'https://gitlab.example.com/jsmith',
              web_path: '/jsmith',
            },
          ],
        },
      });
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [item], {});

      const { nodes } = await workItemsRestResolver(makeNamespace(), {});
      const assigneesWidget = nodes[0].widgets.find((w) => w.type === 'ASSIGNEES');

      expect(assigneesWidget.assignees.nodes).toHaveLength(2);
      expect(assigneesWidget.assignees.nodes[0].username).toBe('jdoe');
      expect(assigneesWidget.assignees.nodes[1].username).toBe('jsmith');
    });

    it('handles missing optional assignee fields', async () => {
      const item = makeRestItem({
        features: {
          assignees: [
            {
              id: 100,
              name: 'John Doe',
              username: 'jdoe',
            },
          ],
        },
      });
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [item], {});

      const { nodes } = await workItemsRestResolver(makeNamespace(), {});
      const assigneesWidget = nodes[0].widgets.find((w) => w.type === 'ASSIGNEES');

      expect(assigneesWidget.assignees.nodes[0]).toMatchObject({
        __typename: 'UserCore',
        id: 'gid://gitlab/User/100',
        name: 'John Doe',
        username: 'jdoe',
        avatarUrl: null,
        webUrl: null,
        webPath: null,
      });
    });
  });

  describe('MILESTONE widget mapping', () => {
    it('returns null milestone when features is null', async () => {
      const item = makeRestItem({ features: null });
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [item], {});

      const { nodes } = await workItemsRestResolver(makeNamespace(), {});
      const milestoneWidget = nodes[0].widgets.find((w) => w.type === 'MILESTONE');

      expect(milestoneWidget).toMatchObject({ __typename: 'WorkItemWidgetMilestone' });
      expect(milestoneWidget.milestone).toBeNull();
    });

    it('returns null milestone when features.milestone is undefined', async () => {
      const item = makeRestItem({ features: {} });
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [item], {});

      const { nodes } = await workItemsRestResolver(makeNamespace(), {});
      const milestoneWidget = nodes[0].widgets.find((w) => w.type === 'MILESTONE');

      expect(milestoneWidget.milestone).toBeNull();
    });

    it('maps milestone from features.milestone to Milestone object', async () => {
      const item = makeRestItem({
        features: {
          milestone: {
            id: 50,
            title: 'v1.0',
            due_date: '2024-12-31',
            start_date: '2024-01-01',
            web_path: 'https://gitlab.example.com/groups/my-group/-/milestones/1',
          },
        },
      });
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [item], {});

      const { nodes } = await workItemsRestResolver(makeNamespace(), {});
      const milestoneWidget = nodes[0].widgets.find((w) => w.type === 'MILESTONE');

      expect(milestoneWidget.milestone).toMatchObject({
        __typename: 'Milestone',
        id: 'gid://gitlab/Milestone/50',
        title: 'v1.0',
        dueDate: '2024-12-31',
        startDate: '2024-01-01',
        webPath: 'https://gitlab.example.com/groups/my-group/-/milestones/1',
      });
    });

    it('handles missing optional milestone fields', async () => {
      const item = makeRestItem({
        features: {
          milestone: {
            id: 50,
            title: 'v1.0',
          },
        },
      });
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [item], {});

      const { nodes } = await workItemsRestResolver(makeNamespace(), {});
      const milestoneWidget = nodes[0].widgets.find((w) => w.type === 'MILESTONE');

      expect(milestoneWidget.milestone).toMatchObject({
        __typename: 'Milestone',
        id: 'gid://gitlab/Milestone/50',
        title: 'v1.0',
        dueDate: null,
        startDate: null,
        webPath: null,
      });
    });
  });

  describe('START_AND_DUE_DATE widget mapping', () => {
    it('does not include START_AND_DUE_DATE widget when features.start_and_due_date is not present', async () => {
      const item = makeRestItem({ features: null });
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [item], {});

      const { nodes } = await workItemsRestResolver(makeNamespace(), {});
      const startAndDueDateWidget = nodes[0].widgets.find((w) => w.type === 'START_AND_DUE_DATE');

      expect(startAndDueDateWidget).toBeUndefined();
    });

    it('maps start_date and due_date to the START_AND_DUE_DATE widget', async () => {
      const item = makeRestItem({
        features: {
          start_and_due_date: {
            start_date: '2024-01-01',
            due_date: '2024-01-31',
          },
        },
      });
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [item], {});

      const { nodes } = await workItemsRestResolver(makeNamespace(), {});
      const startAndDueDateWidget = nodes[0].widgets.find((w) => w.type === 'START_AND_DUE_DATE');

      expect(startAndDueDateWidget).toMatchObject({
        __typename: 'WorkItemWidgetStartAndDueDate',
        type: 'START_AND_DUE_DATE',
        startDate: '2024-01-01',
        dueDate: '2024-01-31',
      });
    });

    it('handles null start_date and due_date', async () => {
      const item = makeRestItem({
        features: {
          start_and_due_date: {
            start_date: null,
            due_date: null,
          },
        },
      });
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_OK, [item], {});

      const { nodes } = await workItemsRestResolver(makeNamespace(), {});
      const startAndDueDateWidget = nodes[0].widgets.find((w) => w.type === 'START_AND_DUE_DATE');

      expect(startAndDueDateWidget).toMatchObject({
        __typename: 'WorkItemWidgetStartAndDueDate',
        type: 'START_AND_DUE_DATE',
        startDate: null,
        dueDate: null,
      });
    });
  });

  describe('error handling', () => {
    it('throws when axios request fails', async () => {
      mockAxios.onGet(ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await expect(workItemsRestResolver(makeNamespace(), {})).rejects.toThrow();
    });
  });
});
