import { GlCollapsibleListbox } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import savedRepliesResponse from 'test_fixtures/graphql/comment_templates/saved_replies.query.graphql.json';
import { mockTracking } from 'helpers/tracking_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CommentTemplatesDropdown from '~/vue_shared/components/markdown/comment_templates_dropdown.vue';
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

  return mountExtended(CommentTemplatesDropdown, {
    propsData: {
      newCommentTemplatePath: '/new',
    },
    apolloProvider: mockApollo,
  });
}

function findDropdownComponent() {
  return wrapper.findComponent(GlCollapsibleListbox);
}

describe('Comment templates dropdown', () => {
  it('fetches data when dropdown gets opened', async () => {
    const mockApollo = createMockApolloProvider(savedRepliesResponse);
    wrapper = createComponent({ mockApollo });

    wrapper.find('.js-comment-template-toggle').trigger('click');

    await waitForPromises();

    expect(savedRepliesResp).toHaveBeenCalled();
  });

  describe('when selecting a comment', () => {
    let trackingSpy;
    let mockApollo;

    beforeEach(() => {
      trackingSpy = mockTracking(undefined, window.document, jest.spyOn);
      mockApollo = createMockApolloProvider(savedRepliesResponse);
      wrapper = createComponent({ mockApollo });
    });

    it('emits a select event', async () => {
      wrapper.find('.js-comment-template-toggle').trigger('click');

      await waitForPromises();

      wrapper.find('.gl-new-dropdown-item').trigger('click');

      expect(wrapper.emitted().select[0]).toEqual(['Saved Reply Content']);
    });

    it('tracks the usage of the saved comment', async () => {
      const dropdown = findDropdownComponent();

      dropdown.vm.$emit('shown');

      await waitForPromises();

      dropdown.vm.$emit('select', savedRepliesResponse.data.currentUser.savedReplies.nodes[0].id);

      await waitForPromises();

      expect(trackingSpy).toHaveBeenCalledWith(
        expect.any(String),
        'i_code_review_saved_replies_use',
        expect.any(Object),
      );
    });
  });
});
