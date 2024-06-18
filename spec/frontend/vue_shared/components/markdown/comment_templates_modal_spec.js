import {
  GlModal,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import savedRepliesResponse from 'test_fixtures/graphql/comment_templates/saved_replies.query.graphql.json';
import { mockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CommentTemplatesDropdown from '~/vue_shared/components/markdown/comment_templates_modal.vue';
import savedRepliesQuery from 'ee_else_ce/vue_shared/components/markdown/saved_replies.query.graphql';
import {
  TRACKING_SAVED_REPLIES_USE,
  TRACKING_SAVED_REPLIES_USE_IN_MR,
  TRACKING_SAVED_REPLIES_USE_IN_OTHER,
} from '~/vue_shared/components/markdown/constants';

let wrapper;
let savedRepliesResp;

const newCommentTemplatePaths = [
  { href: '/user/comment_templates', text: 'Manage user' },
  { href: '/group/comment_templates', text: 'Manage group' },
];

function createMockApolloProvider(response) {
  Vue.use(VueApollo);

  savedRepliesResp = jest
    .fn()
    .mockResolvedValue({ data: { currentUser: { ...response.data.object } } });

  const requestHandlers = [[savedRepliesQuery, savedRepliesResp]];

  return createMockApollo(requestHandlers);
}

function createComponent(options = {}) {
  const { mockApollo } = options;

  return shallowMountExtended(CommentTemplatesDropdown, {
    propsData: {
      newCommentTemplatePaths,
    },
    apolloProvider: mockApollo,
    stubs: {
      GlModal,
      GlDisclosureDropdown,
      GlDisclosureDropdownGroup,
      GlDisclosureDropdownItem,
    },
  });
}

const findToggleButton = () => wrapper.findByTestId('comment-templates-dropdown-toggle');
const findModalComponent = () => wrapper.findComponent(GlModal);
const findActionButton = () =>
  findModalComponent().findComponent(GlDisclosureDropdownItem).find('button');

async function selectSavedReply() {
  findToggleButton().vm.$emit('click');

  await waitForPromises();

  await findActionButton().trigger('click');
}

useMockLocationHelper();

describe('Comment templates dropdown', () => {
  it('fetches data when dropdown gets opened', async () => {
    const mockApollo = createMockApolloProvider(savedRepliesResponse);
    wrapper = createComponent({ mockApollo });

    findToggleButton().vm.$emit('click');

    await waitForPromises();

    expect(savedRepliesResp).toHaveBeenCalled();
  });

  it('renders multiple manage links', () => {
    const mockApollo = createMockApolloProvider(savedRepliesResponse);
    wrapper = createComponent({ mockApollo });

    findToggleButton().vm.$emit('click');

    const manageDropdown = wrapper.findByTestId('manage-dropdown');
    const links = manageDropdown.props('items');

    expect(links).toHaveLength(newCommentTemplatePaths.length);
    expect(links).toBe(newCommentTemplatePaths);
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
      await selectSavedReply();

      expect(wrapper.emitted().select[0]).toEqual(['Saved Reply Content']);
    });

    describe('tracking', () => {
      it('always sends two tracking events', async () => {
        await selectSavedReply();

        expect(trackingSpy).toHaveBeenCalledTimes(2);
      });

      it('tracks overall usage', async () => {
        await selectSavedReply();

        expect(trackingSpy).toHaveBeenCalledWith(
          undefined,
          TRACKING_SAVED_REPLIES_USE,
          expect.any(Object),
        );
      });

      describe('MR-specific usage event', () => {
        it('is sent when in an MR', async () => {
          window.location.toString.mockReturnValue('this/looks/like/a/-/merge_requests/1');

          await selectSavedReply();

          expect(trackingSpy).toHaveBeenCalledWith(
            undefined,
            TRACKING_SAVED_REPLIES_USE_IN_MR,
            expect.any(Object),
          );
        });

        it('is not sent when not in an MR', async () => {
          window.location.toString.mockReturnValue('this/looks/like/a/-/issues/1');

          await selectSavedReply();

          expect(trackingSpy).not.toHaveBeenCalledWith(
            expect.any(String),
            TRACKING_SAVED_REPLIES_USE_IN_MR,
            expect.any(Object),
          );
        });
      });

      describe('non-MR usage event', () => {
        it('is sent when not in an MR', async () => {
          window.location.toString.mockReturnValue('this/looks/like/a/-/issues/1');

          await selectSavedReply();

          expect(trackingSpy).toHaveBeenCalledWith(
            undefined,
            TRACKING_SAVED_REPLIES_USE_IN_OTHER,
            expect.any(Object),
          );
        });

        it('is not sent when in an MR', async () => {
          window.location.toString.mockReturnValue('this/looks/like/a/-/merge_requests/1');

          await selectSavedReply();

          expect(trackingSpy).not.toHaveBeenCalledWith(
            expect.any(String),
            TRACKING_SAVED_REPLIES_USE_IN_OTHER,
            expect.any(Object),
          );
        });
      });
    });
  });
});
