import Vue from 'vue';
import { mount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import savedRepliesResponse from 'test_fixtures/graphql/saved_replies/saved_replies.query.graphql.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import IndexPage from '~/saved_replies/pages/index.vue';
import ListItem from '~/saved_replies/components/list_item.vue';
import savedRepliesQuery from '~/saved_replies/queries/saved_replies.query.graphql';

let wrapper;

function createMockApolloProvider(response) {
  Vue.use(VueApollo);

  const requestHandlers = [[savedRepliesQuery, jest.fn().mockResolvedValue(response)]];

  return createMockApollo(requestHandlers);
}

function createComponent(options = {}) {
  const { mockApollo } = options;

  return mount(IndexPage, {
    apolloProvider: mockApollo,
  });
}

describe('Saved replies index page component', () => {
  it('renders list of saved replies', async () => {
    const mockApollo = createMockApolloProvider(savedRepliesResponse);
    const savedReplies = savedRepliesResponse.data.currentUser.savedReplies.nodes;
    wrapper = createComponent({ mockApollo });

    await waitForPromises();

    expect(wrapper.findAllComponents(ListItem).length).toBe(2);
    expect(wrapper.findAllComponents(ListItem).at(0).props('reply')).toEqual(
      expect.objectContaining(savedReplies[0]),
    );
    expect(wrapper.findAllComponents(ListItem).at(1).props('reply')).toEqual(
      expect.objectContaining(savedReplies[1]),
    );
  });
});
