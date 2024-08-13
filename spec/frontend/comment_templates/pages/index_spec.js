import Vue from 'vue';
import VueApollo from 'vue-apollo';
import noSavedRepliesResponse from 'test_fixtures/graphql/comment_templates/saved_replies_empty.query.graphql.json';
import savedRepliesResponse from 'test_fixtures/graphql/comment_templates/saved_replies.query.graphql.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import IndexPage from '~/comment_templates/pages/index.vue';
import ListItem from '~/comment_templates/components/list_item.vue';
import savedRepliesQuery from '~/pages/profiles/comment_templates/queries/saved_replies.query.graphql';
import deleteSavedReplyMutation from '~/pages/profiles/comment_templates/queries/delete_saved_reply.mutation.graphql';

let wrapper;

function createMockApolloProvider(response) {
  Vue.use(VueApollo);

  const requestHandlers = [[savedRepliesQuery, jest.fn().mockResolvedValue(response)]];

  return createMockApollo(requestHandlers);
}

function createComponent(options = {}) {
  const { mockApollo } = options;

  return mountExtended(IndexPage, {
    apolloProvider: mockApollo,
    provide: {
      fetchAllQuery: savedRepliesQuery,
      deleteMutation: deleteSavedReplyMutation,
    },
  });
}

describe('Comment templates index page component', () => {
  it('does not render any list items when response is empty', async () => {
    const mockApollo = createMockApolloProvider(noSavedRepliesResponse);
    wrapper = createComponent({ mockApollo });

    await waitForPromises();

    expect(wrapper.findAllComponents(ListItem).length).toBe(0);
  });

  it('renders list of comment templates', async () => {
    const mockApollo = createMockApolloProvider(savedRepliesResponse);
    const savedReplies = savedRepliesResponse.data.object.savedReplies.nodes;
    wrapper = createComponent({ mockApollo });

    await waitForPromises();

    expect(wrapper.findAllComponents(ListItem).length).toBe(2);
    expect(wrapper.findAllComponents(ListItem).at(0).props('template')).toEqual(
      expect.objectContaining(savedReplies[0]),
    );
    expect(wrapper.findAllComponents(ListItem).at(1).props('template')).toEqual(
      expect.objectContaining(savedReplies[1]),
    );
  });

  it('render comment templates count', async () => {
    const mockApollo = createMockApolloProvider(savedRepliesResponse);
    wrapper = createComponent({ mockApollo });

    await waitForPromises();

    expect(wrapper.findByTestId('crud-count').text()).toContain('2');
  });
});
