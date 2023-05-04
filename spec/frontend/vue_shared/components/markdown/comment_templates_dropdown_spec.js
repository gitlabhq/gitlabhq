import Vue from 'vue';
import VueApollo from 'vue-apollo';
import savedRepliesResponse from 'test_fixtures/graphql/comment_templates/saved_replies.query.graphql.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { updateText } from '~/lib/utils/text_markdown';
import CommentTemplatesDropdown from '~/vue_shared/components/markdown/comment_templates_dropdown.vue';
import savedRepliesQuery from '~/vue_shared/components/markdown/saved_replies.query.graphql';

jest.mock('~/lib/utils/text_markdown');

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

  return mountExtended(CommentTemplatesDropdown, {
    attachTo: '#root',
    propsData: {
      newCommentTemplatePath: '/new',
    },
    apolloProvider: mockApollo,
  });
}

describe('Comment templates dropdown', () => {
  beforeEach(() => {
    setHTMLFixture('<div class="md-area"><textarea></textarea><div id="root"></div></div>');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('fetches data when dropdown gets opened', async () => {
    const mockApollo = createMockApolloProvider(savedRepliesResponse);
    wrapper = createComponent({ mockApollo });

    wrapper.find('.js-comment-template-toggle').trigger('click');

    await waitForPromises();

    expect(savedRepliesResp).toHaveBeenCalled();
  });

  it('adds content to textarea', async () => {
    const mockApollo = createMockApolloProvider(savedRepliesResponse);
    wrapper = createComponent({ mockApollo });

    wrapper.find('.js-comment-template-toggle').trigger('click');

    await waitForPromises();

    wrapper.find('.gl-new-dropdown-item').trigger('click');

    expect(updateText).toHaveBeenCalledWith({
      textArea: document.querySelector('textarea'),
      tag: savedRepliesResponse.data.currentUser.savedReplies.nodes[0].content,
      cursorOffset: 0,
      wrap: false,
    });
  });
});
