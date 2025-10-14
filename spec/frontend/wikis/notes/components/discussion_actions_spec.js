import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import DiscussionActions from '~/wikis/wiki_notes/components/discussion_actions.vue';
import ResolveDiscussionButton from '~/notes/components/discussion_resolve_button.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import discussionToggleResolveMutation from '~/wikis/wiki_notes/graphql/discussion_toggle_resolve.mutation.graphql';

Vue.use(VueApollo);

describe('DiscussionActions', () => {
  let wrapper;
  let mockApollo;

  const createWrapper = (propsData = {}) => {
    mockApollo = createMockApollo();
    mockApollo.defaultClient.mutate = jest.fn();

    wrapper = shallowMountExtended(DiscussionActions, {
      apolloProvider: mockApollo,
      propsData: {
        discussionId: '1',
        showResolveButton: true,
        ...propsData,
      },
    });
  };

  const findResolveDiscussionButton = () => wrapper.findComponent(ResolveDiscussionButton);

  describe('when showResolveButton is true', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('mounts without error', () => {
      expect(wrapper.exists()).toBe(true);
    });

    it('does show the resolve-discussion-button', () => {
      expect(findResolveDiscussionButton().exists()).toBe(true);
      expect(findResolveDiscussionButton().props('buttonTitle')).toBe('Resolve thread');
    });

    it('does set resolve-discussion-button to is-loading when it is clicked', async () => {
      // ensure the mutation does not resolve before the prop is tested
      mockApollo.defaultClient.mutate = jest.fn(() => new Promise(() => {}));

      await findResolveDiscussionButton().vm.$emit('onClick');
      await nextTick();

      expect(findResolveDiscussionButton().props('isResolving')).toBe(true);
    });

    it('sends a discussionToggleResolveMutation when it is clicked', async () => {
      await findResolveDiscussionButton().vm.$emit('onClick');
      await nextTick();

      expect(mockApollo.defaultClient.mutate).toHaveBeenCalledWith({
        mutation: discussionToggleResolveMutation,
        variables: {
          id: '1',
          resolve: true,
        },
      });
    });
  });

  describe('when the discussion is resolved', () => {
    beforeEach(() => {
      createWrapper({ isResolved: true });
    });

    it('does show the resolve-discussion-button with the correct text', () => {
      expect(findResolveDiscussionButton().exists()).toBe(true);
      expect(findResolveDiscussionButton().props('buttonTitle')).toBe('Reopen thread');
    });

    it('sends a discussionToggleResolveMutation when it is clicked', async () => {
      await findResolveDiscussionButton().vm.$emit('onClick');
      await nextTick();

      expect(mockApollo.defaultClient.mutate).toHaveBeenCalledWith({
        mutation: discussionToggleResolveMutation,
        variables: {
          id: '1',
          resolve: false,
        },
      });
    });
  });

  describe('when showResolveButton is false', () => {
    beforeEach(() => {
      createWrapper({ showResolveButton: false });
    });

    it('mounts without error', () => {
      expect(wrapper.exists()).toBe(true);
    });

    it('does not show the resolve-discussion-button', () => {
      expect(findResolveDiscussionButton().exists()).toBe(false);
    });
  });
});
