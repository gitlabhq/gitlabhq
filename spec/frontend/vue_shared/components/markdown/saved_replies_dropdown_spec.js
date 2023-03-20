import Vue from 'vue';
import VueApollo from 'vue-apollo';
import savedRepliesResponse from 'test_fixtures/graphql/saved_replies/saved_replies.query.graphql.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import SavedRepliesDropdown from '~/vue_shared/components/markdown/saved_replies_dropdown.vue';
import savedRepliesQuery from '~/vue_shared/components/markdown/saved_replies.query.graphql';

let wrapper;
let savedRepliesResp;

function createMockApolloProvider(response) {
  Vue.use(VueApollo);

  savedRepliesResp = jest.fn().mockResolvedValue(response);

  const requestHandlers = [[savedRepliesQuery, savedRepliesResp]];

  return createMockApollo(requestHandlers);
}

function createComponent(options = {}) {
  const { mockApollo } = options;

  return mountExtended(SavedRepliesDropdown, {
    propsData: {
      newSavedRepliesPath: '/new',
    },
    apolloProvider: mockApollo,
  });
}

describe('Saved replies dropdown', () => {
  it('fetches data when dropdown gets opened', async () => {
    const mockApollo = createMockApolloProvider(savedRepliesResponse);
    wrapper = createComponent({ mockApollo });

    wrapper.findByTestId('saved-replies-dropdown-toggle').trigger('click');

    await waitForPromises();

    expect(savedRepliesResp).toHaveBeenCalled();
  });

  it('adds markdown toolbar attributes to dropdown items', async () => {
    const mockApollo = createMockApolloProvider(savedRepliesResponse);
    wrapper = createComponent({ mockApollo });

    wrapper.findByTestId('saved-replies-dropdown-toggle').trigger('click');

    await waitForPromises();

    expect(wrapper.findByTestId('saved-reply-dropdown-item').attributes()).toEqual(
      expect.objectContaining({
        'data-md-cursor-offset': '0',
        'data-md-prepend': 'true',
        'data-md-tag': 'Saved Reply Content',
      }),
    );
  });
});
