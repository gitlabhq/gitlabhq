import { GlCollapse, GlPopover } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Cookies from 'js-cookie';
import DesignDiscussion from '~/design_management/components/design_notes/design_discussion.vue';
import DesignSidebar from '~/design_management/components/design_sidebar.vue';
import DesignTodoButton from '~/design_management/components/design_todo_button.vue';
import updateActiveDiscussionMutation from '~/design_management/graphql/mutations/update_active_discussion.mutation.graphql';
import Participants from '~/sidebar/components/participants/participants.vue';
import design from '../mock_data/design';

const scrollIntoViewMock = jest.fn();
HTMLElement.prototype.scrollIntoView = scrollIntoViewMock;

const updateActiveDiscussionMutationVariables = {
  mutation: updateActiveDiscussionMutation,
  variables: {
    id: design.discussions.nodes[0].notes.nodes[0].id,
    source: 'discussion',
  },
};

const $route = {
  params: {
    id: '1',
  },
};

const cookieKey = 'hide_design_resolved_comments_popover';

const mutate = jest.fn().mockResolvedValue();

describe('Design management design sidebar component', () => {
  let wrapper;

  const findDiscussions = () => wrapper.findAll(DesignDiscussion);
  const findFirstDiscussion = () => findDiscussions().at(0);
  const findUnresolvedDiscussions = () => wrapper.findAll('[data-testid="unresolved-discussion"]');
  const findResolvedDiscussions = () => wrapper.findAll('[data-testid="resolved-discussion"]');
  const findParticipants = () => wrapper.find(Participants);
  const findCollapsible = () => wrapper.find(GlCollapse);
  const findToggleResolvedCommentsButton = () => wrapper.find('[data-testid="resolved-comments"]');
  const findPopover = () => wrapper.find(GlPopover);
  const findNewDiscussionDisclaimer = () =>
    wrapper.find('[data-testid="new-discussion-disclaimer"]');

  function createComponent(props = {}) {
    wrapper = shallowMount(DesignSidebar, {
      propsData: {
        design,
        resolvedDiscussionsExpanded: false,
        markdownPreviewPath: '',
        ...props,
      },
      mocks: {
        $route,
        $apollo: {
          mutate,
        },
      },
      stubs: { GlPopover },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders participants', () => {
    createComponent();

    expect(findParticipants().exists()).toBe(true);
  });

  it('passes the correct amount of participants to the Participants component', () => {
    createComponent();

    expect(findParticipants().props('participants')).toHaveLength(1);
  });

  it('renders To-Do button', () => {
    createComponent();

    expect(wrapper.find(DesignTodoButton).exists()).toBe(true);
  });

  describe('when has no discussions', () => {
    beforeEach(() => {
      createComponent({
        design: {
          ...design,
          discussions: {
            nodes: [],
          },
        },
      });
    });

    it('does not render discussions', () => {
      expect(findDiscussions().exists()).toBe(false);
    });

    it('renders a message about possibility to create a new discussion', () => {
      expect(findNewDiscussionDisclaimer().exists()).toBe(true);
    });
  });

  describe('when has discussions', () => {
    beforeEach(() => {
      Cookies.set(cookieKey, true);
      createComponent();
    });

    it('renders correct amount of unresolved discussions', () => {
      expect(findUnresolvedDiscussions()).toHaveLength(1);
    });

    it('renders correct amount of resolved discussions', () => {
      expect(findResolvedDiscussions()).toHaveLength(1);
    });

    it('has resolved comments collapsible collapsed', () => {
      expect(findCollapsible().attributes('visible')).toBeUndefined();
    });

    it('emits toggleResolveComments event on resolve comments button click', () => {
      findToggleResolvedCommentsButton().vm.$emit('click');
      expect(wrapper.emitted('toggleResolvedComments')).toHaveLength(1);
    });

    it('opens a collapsible when resolvedDiscussionsExpanded prop changes to true', () => {
      expect(findCollapsible().attributes('visible')).toBeUndefined();
      wrapper.setProps({
        resolvedDiscussionsExpanded: true,
      });
      return wrapper.vm.$nextTick().then(() => {
        expect(findCollapsible().attributes('visible')).toBe('true');
      });
    });

    it('does not popover about resolved comments', () => {
      expect(findPopover().exists()).toBe(false);
    });

    it('sends a mutation to set an active discussion when clicking on a discussion', () => {
      findFirstDiscussion().trigger('click');

      expect(mutate).toHaveBeenCalledWith(updateActiveDiscussionMutationVariables);
    });

    it('sends a mutation to reset an active discussion when clicking outside of discussion', () => {
      wrapper.trigger('click');

      expect(mutate).toHaveBeenCalledWith({
        ...updateActiveDiscussionMutationVariables,
        variables: { id: undefined, source: 'discussion' },
      });
    });

    it('emits correct event on discussion create note error', () => {
      findFirstDiscussion().vm.$emit('create-note-error', 'payload');
      expect(wrapper.emitted('onDesignDiscussionError')).toEqual([['payload']]);
    });

    it('emits correct event on discussion update note error', () => {
      findFirstDiscussion().vm.$emit('update-note-error', 'payload');
      expect(wrapper.emitted('updateNoteError')).toEqual([['payload']]);
    });

    it('emits correct event on discussion resolve error', () => {
      findFirstDiscussion().vm.$emit('resolve-discussion-error', 'payload');
      expect(wrapper.emitted('resolveDiscussionError')).toEqual([['payload']]);
    });

    it('changes prop correctly on opening discussion form', () => {
      findFirstDiscussion().vm.$emit('open-form', 'some-id');

      return wrapper.vm.$nextTick().then(() => {
        expect(findFirstDiscussion().props('discussionWithOpenForm')).toBe('some-id');
      });
    });
  });

  describe('when all discussions are resolved', () => {
    beforeEach(() => {
      createComponent({
        design: {
          ...design,
          discussions: {
            nodes: [
              {
                id: 'discussion-id',
                replyId: 'discussion-reply-id',
                resolved: true,
                notes: {
                  nodes: [
                    {
                      id: 'note-id',
                      body: '123',
                      author: {
                        name: 'Administrator',
                        username: 'root',
                        webUrl: 'link-to-author',
                        avatarUrl: 'link-to-avatar',
                      },
                    },
                  ],
                },
              },
            ],
          },
        },
      });
    });

    it('renders a message about possibility to create a new discussion', () => {
      expect(findNewDiscussionDisclaimer().exists()).toBe(true);
    });

    it('does not render unresolved discussions', () => {
      expect(findUnresolvedDiscussions()).toHaveLength(0);
    });
  });

  describe('when showing resolved discussions for the first time', () => {
    beforeEach(() => {
      Cookies.set(cookieKey, false);
      createComponent();
    });

    it('renders a popover if we show resolved comments collapsible for the first time', () => {
      expect(findPopover().exists()).toBe(true);
    });

    it('scrolls to resolved threads link', () => {
      expect(scrollIntoViewMock).toHaveBeenCalled();
    });

    it('dismisses a popover on the outside click', () => {
      wrapper.trigger('click');
      return wrapper.vm.$nextTick(() => {
        expect(findPopover().exists()).toBe(false);
      });
    });

    it(`sets a ${cookieKey} cookie on clicking outside the popover`, () => {
      jest.spyOn(Cookies, 'set');
      wrapper.trigger('click');
      expect(Cookies.set).toHaveBeenCalledWith(cookieKey, 'true', { expires: 365 * 10 });
    });
  });
});
