import { shallowMount, mount } from '@vue/test-utils';
import { discussionMock } from '../../notes/mock_data';
import DiscussionActions from '~/notes/components/discussion_actions.vue';
import ReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import ResolveDiscussionButton from '~/notes/components/discussion_resolve_button.vue';
import ResolveWithIssueButton from '~/notes/components/discussion_resolve_with_issue_button.vue';
import JumpToNextDiscussionButton from '~/notes/components/discussion_jump_to_next_button.vue';
import createStore from '~/notes/stores';

// NOTE: clone mock_data so that it is not accidentally mutated
const createDiscussionMock = (props = {}) =>
  Object.assign(JSON.parse(JSON.stringify(discussionMock)), props);
const createNoteMock = (props = {}) =>
  Object.assign(JSON.parse(JSON.stringify(discussionMock.notes[0])), props);
const createResolvableNote = () =>
  createNoteMock({ resolvable: true, current_user: { can_resolve: true } });
const createUnresolvableNote = () =>
  createNoteMock({ resolvable: false, current_user: { can_resolve: false } });
const createUnallowedNote = () =>
  createNoteMock({ resolvable: true, current_user: { can_resolve: false } });

describe('DiscussionActions', () => {
  let wrapper;
  const createComponentFactory = (shallow = true) => props => {
    const store = createStore();
    const mountFn = shallow ? shallowMount : mount;

    wrapper = mountFn(DiscussionActions, {
      store,
      propsData: {
        discussion: discussionMock,
        isResolving: false,
        resolveButtonTitle: 'Resolve discussion',
        resolveWithIssuePath: '/some/issue/path',
        shouldShowJumpToNextDiscussion: true,
        ...props,
      },
      sync: false,
      attachToDocument: true,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendering', () => {
    const createComponent = createComponentFactory();

    it('renders reply placeholder, resolve discussion button, resolve with issue button and jump to next discussion button', () => {
      createComponent();
      expect(wrapper.find(ReplyPlaceholder).exists()).toBe(true);
      expect(wrapper.find(ResolveDiscussionButton).exists()).toBe(true);
      expect(wrapper.find(ResolveWithIssueButton).exists()).toBe(true);
      expect(wrapper.find(JumpToNextDiscussionButton).exists()).toBe(true);
    });

    it('only renders reply placholder if disccusion is not resolvable', () => {
      const discussion = { ...discussionMock };
      discussion.resolvable = false;
      createComponent({ discussion });

      expect(wrapper.find(ReplyPlaceholder).exists()).toBe(true);
      expect(wrapper.find(ResolveDiscussionButton).exists()).toBe(false);
      expect(wrapper.find(ResolveWithIssueButton).exists()).toBe(false);
      expect(wrapper.find(JumpToNextDiscussionButton).exists()).toBe(false);
    });

    it('does not render resolve with issue button if resolveWithIssuePath is falsy', () => {
      createComponent({ resolveWithIssuePath: '' });

      expect(wrapper.find(ResolveWithIssueButton).exists()).toBe(false);
    });

    it('does not render jump to next discussion button if shouldShowJumpToNextDiscussion is false', () => {
      createComponent({ shouldShowJumpToNextDiscussion: false });

      expect(wrapper.find(JumpToNextDiscussionButton).exists()).toBe(false);
    });

    describe.each`
      desc                         | notes                                                 | shouldRender
      ${'with no notes'}           | ${[]}                                                 | ${true}
      ${'with resolvable notes'}   | ${[createResolvableNote(), createResolvableNote()]}   | ${true}
      ${'with unresolvable notes'} | ${[createResolvableNote(), createUnresolvableNote()]} | ${true}
      ${'with unallowed note'}     | ${[createResolvableNote(), createUnallowedNote()]}    | ${false}
    `('$desc', ({ notes, shouldRender }) => {
      beforeEach(() => {
        createComponent({
          discussion: createDiscussionMock({ notes }),
        });
      });

      it(shouldRender ? 'renders resolve buttons' : 'does not render resolve buttons', () => {
        expect(wrapper.find(ResolveDiscussionButton).exists()).toBe(shouldRender);
        expect(wrapper.find(ResolveWithIssueButton).exists()).toBe(shouldRender);
      });
    });
  });

  describe('events handling', () => {
    const createComponent = createComponentFactory(false);

    beforeEach(() => {
      createComponent();
    });

    it('emits showReplyForm event when clicking on reply placeholder', () => {
      jest.spyOn(wrapper.vm, '$emit');
      wrapper
        .find(ReplyPlaceholder)
        .find('button')
        .trigger('click');
      expect(wrapper.vm.$emit).toHaveBeenCalledWith('showReplyForm');
    });

    it('emits resolve event when clicking on resolve button', () => {
      jest.spyOn(wrapper.vm, '$emit');
      wrapper
        .find(ResolveDiscussionButton)
        .find('button')
        .trigger('click');
      expect(wrapper.vm.$emit).toHaveBeenCalledWith('resolve');
    });

    it('emits jumpToNextDiscussion event when clicking on jump to next discussion button', () => {
      jest.spyOn(wrapper.vm, '$emit');
      wrapper
        .find(JumpToNextDiscussionButton)
        .find('button')
        .trigger('click');
      expect(wrapper.vm.$emit).toHaveBeenCalledWith('jumpToNextDiscussion');
    });
  });
});
