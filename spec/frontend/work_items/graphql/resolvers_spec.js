import createMockApollo from 'helpers/mock_apollo_helper';
import { updateNewWorkItemCache } from '~/work_items/graphql/resolvers';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import updateNewWorkItemMutation from '~/work_items/graphql/update_new_work_item.mutation.graphql';
import {
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_LABELS,
  WIDGET_TYPE_DESCRIPTION,
} from '~/work_items/constants';
import { createWorkItemQueryResponse } from '../mock_data';

describe('work items graphql resolvers', () => {
  describe('updateNewWorkItemCache', () => {
    let mockApolloClient;

    const fullPath = 'fullPath';
    const fullPathWithId = 'fullPath-issue-id';
    const iid = 'new-work-item-iid';

    const mutate = (input) => {
      mockApolloClient.mutate({
        mutation: updateNewWorkItemMutation,
        variables: {
          input: {
            workItemType: 'issue',
            fullPath,
            ...input,
          },
        },
      });
    };

    const query = async (widgetName = null) => {
      const queryResult = await mockApolloClient.query({
        query: workItemByIidQuery,
        variables: { fullPath: fullPathWithId, iid },
      });

      if (widgetName == null) return queryResult.data.workspace.workItem;

      return queryResult.data.workspace.workItem.widgets.find(({ type }) => type === widgetName);
    };

    beforeEach(() => {
      const mockApollo = createMockApollo([], {
        Mutation: {
          updateNewWorkItem(_, { input }, { cache }) {
            updateNewWorkItemCache(input, cache);
          },
        },
      });
      mockApollo.clients.defaultClient.cache.writeQuery({
        query: workItemByIidQuery,
        variables: { fullPath: fullPathWithId, iid },
        data: createWorkItemQueryResponse.data,
      });
      mockApolloClient = mockApollo.clients.defaultClient;
    });

    describe('with assignees input', () => {
      it('updates assignees', async () => {
        const assigneeNodes = [
          {
            __typename: 'UserCore',
            id: 'gid://gitlab/User/1',
            avatarUrl:
              'https://www.gravatar.com/avatar/ef6d2fd5b97d4a697eec45321f37683003fa105bb80c395d4e720f572898d46c?s=80&d=identicon',
            name: 'Administrator',
            username: 'root',
            webUrl: 'http://gdk.local:3000/root',
            webPath: '/root',
          },
          {
            __typename: 'UserCore',
            id: 'gid://gitlab/User/2',
            avatarUrl:
              'https://www.gravatar.com/avatar/d57c3c73a86cae08b80b28f451073d1287fa1c750498f04780ec1b6586ed21ac?s=80&d=identicon',
            name: 'User',
            username: 'user',
            webUrl: 'http://gdk.local:3000/user',
            webPath: '/user',
          },
        ];

        await mutate({ assignees: assigneeNodes });

        const queryResult = await query(WIDGET_TYPE_ASSIGNEES);
        expect(queryResult).toMatchObject({
          assignees: {
            nodes: assigneeNodes,
          },
        });
      });
    });

    describe('with labels input', () => {
      it('updates labels', async () => {
        await mutate({ labels: [] });

        const queryResult = await query(WIDGET_TYPE_LABELS);
        expect(queryResult).toMatchObject({ labels: { nodes: [] } });
      });
    });

    describe('with description input', () => {
      it('updates description', async () => {
        await mutate({ description: 'Description' });

        const queryResult = await query(WIDGET_TYPE_DESCRIPTION);
        expect(queryResult).toMatchObject({ description: 'Description' });
      });
    });

    describe('with confidential input', () => {
      it('updates confidential', async () => {
        await mutate({ confidential: true });

        let queryResult = await query();
        expect(queryResult).toMatchObject({ confidential: true });

        await mutate({ confidential: false });

        queryResult = await query();
        expect(queryResult).toMatchObject({ confidential: false });
      });
    });

    describe('with title input', () => {
      it('updates title', async () => {
        await mutate({ title: 'Title' });

        const queryResult = await query();
        expect(queryResult).toMatchObject({ title: 'Title' });
      });
    });
  });
});
