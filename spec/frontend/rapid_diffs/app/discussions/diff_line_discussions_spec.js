import { GlButton } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import setWindowLocation from 'helpers/set_window_location_helper';
import { isLoggedIn } from '~/lib/utils/common_utils';
import DiffLineDiscussions from '~/rapid_diffs/app/discussions/diff_line_discussions.vue';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import DiffDiscussions from '~/rapid_diffs/app/discussions/diff_discussions.vue';
import DraftNote from '~/rapid_diffs/app/discussions/draft_note.vue';
import NewLineDiscussionForm from '~/rapid_diffs/app/discussions/new_line_discussion_form.vue';
import NoteSignedOutWidget from '~/rapid_diffs/app/discussions/note_signed_out_widget.vue';
import { markAsScrolled } from '~/rapid_diffs/utils/scroll_to_linked_fragment';

jest.mock('~/lib/utils/common_utils');
jest.mock('~/rapid_diffs/utils/scroll_to_linked_fragment', () => ({
  hasScrolled: jest.fn(() => false),
  markAsScrolled: jest.fn(),
}));

describe('DiffLineDiscussions', () => {
  let wrapper;

  const createDiscussion = (overrides = {}) => ({
    id: '1',
    diff_discussion: true,
    hidden: false,
    notes: [{}],
    ...overrides,
  });

  const createDraft = (overrides = {}) => ({
    isDraft: true,
    draft: { id: 'draft-1', author: { id: 1 }, created_at: new Date().toISOString() },
    position: { old_line: 5, new_line: 5 },
    ...overrides,
  });

  const createComponent = (
    discussions = [],
    provide = { userPermissions: { can_create_note: true } },
    propsOverrides = {},
  ) => {
    wrapper = shallowMount(DiffLineDiscussions, {
      propsData: { discussions, ...propsOverrides },
      provide,
    });
  };

  const mountComponent = (discussions = [], { filePaths } = {}) => {
    createTestingPinia({ stubActions: false });
    const store = useDiffDiscussions();
    wrapper = mount(DiffLineDiscussions, {
      propsData: { discussions },
      provide: {
        store,
        userPermissions: { can_create_note: true },
        endpoints: {},
        ...(filePaths ? { filePaths } : {}),
      },
      attachTo: document.body,
    });
  };

  it('shows regular discussions', () => {
    const discussion = createDiscussion();
    createComponent([discussion]);
    const rendered = wrapper.findComponent(DiffDiscussions).props('discussions');
    expect(rendered).toHaveLength(1);
    expect(rendered[0]).toStrictEqual(discussion);
  });

  it('shows new discussion form', () => {
    const form = { id: 'form-1', isForm: true };
    createComponent([form]);
    expect(wrapper.findComponent(NewLineDiscussionForm).props('discussion')).toBe(form);
  });

  describe('scrollToNoteFragment', () => {
    let mock;

    const discussions = [
      createDiscussion({
        notes: [{ id: 'abc', author: { id: 1 }, created_at: new Date().toDateString() }],
      }),
    ];

    const createLinkedComponent = ({ filePaths, linkedFileData } = {}) => {
      wrapper = shallowMount(DiffLineDiscussions, {
        propsData: { discussions: [] },
        provide: {
          userPermissions: { can_create_note: true },
          ...(filePaths ? { filePaths } : {}),
          ...(linkedFileData ? { linkedFileData } : {}),
        },
        attachTo: document.body,
      });
      const anchor = document.createElement('a');
      anchor.href = '#note_abc';
      document.body.appendChild(anchor);
    };

    beforeEach(() => {
      mock = jest.fn();
      jest.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(mock);
      markAsScrolled.mockClear();
      setWindowLocation('#note_abc');
    });

    it('marks as scrolled after clicking the note anchor', () => {
      mountComponent(discussions);
      expect(markAsScrolled).toHaveBeenCalled();
    });

    it('scrolls when linkedFileData matches filePaths', () => {
      createLinkedComponent({
        filePaths: { oldPath: 'foo/bar.rb', newPath: 'foo/bar.rb' },
        linkedFileData: { old_path: 'foo/bar.rb', new_path: 'foo/bar.rb' },
      });
      wrapper.vm.scrollToNoteFragment();
      expect(markAsScrolled).toHaveBeenCalled();
    });

    it('does not scroll when linkedFileData does not match filePaths', () => {
      createLinkedComponent({
        filePaths: { oldPath: 'foo/bar.rb', newPath: 'foo/bar.rb' },
        linkedFileData: { old_path: 'other/file.rb', new_path: 'other/file.rb' },
      });
      wrapper.vm.scrollToNoteFragment();
      expect(markAsScrolled).not.toHaveBeenCalled();
    });

    it('does not scroll when linkedFileData is present but filePaths is not injected', () => {
      createLinkedComponent({ linkedFileData: { old_path: 'foo/bar.rb', new_path: 'foo/bar.rb' } });
      wrapper.vm.scrollToNoteFragment();
      expect(markAsScrolled).not.toHaveBeenCalled();
    });
  });

  describe('line highlighting', () => {
    const getDiscussionWrapper = () =>
      wrapper.findComponent(DiffDiscussions).element.closest('[class]');

    it('emits highlight with line range on mouseenter', () => {
      const discussion = createDiscussion({
        position: { old_path: 'old', new_path: 'old', new_line: '1', old_line: '1' },
      });
      createComponent([discussion]);
      getDiscussionWrapper().dispatchEvent(new MouseEvent('mouseenter'));
      expect(wrapper.emitted('highlight')).toHaveLength(1);
      expect(wrapper.emitted('highlight')[0]).toEqual([
        {
          start: { old_line: '1', new_line: '1' },
          end: { old_line: '1', new_line: '1' },
        },
      ]);
    });

    it('emits highlight with line_range when present', () => {
      const lineRange = {
        start: { old_line: 1, new_line: null },
        end: { old_line: 5, new_line: null },
      };
      const discussion = createDiscussion({
        position: {
          old_path: 'old',
          new_path: 'old',
          new_line: null,
          old_line: 1,
          line_range: lineRange,
        },
      });
      createComponent([discussion]);
      getDiscussionWrapper().dispatchEvent(new MouseEvent('mouseenter'));
      expect(wrapper.emitted('highlight')[0]).toEqual([lineRange]);
    });

    it('emits highlight on mouseenter for form discussions', () => {
      const form = {
        isForm: true,
        position: { old_line: '1', new_line: '1' },
      };
      createComponent([form]);
      const formWrapper = wrapper.findComponent(NewLineDiscussionForm).element.closest('[class]');
      formWrapper.dispatchEvent(new MouseEvent('mouseenter'));
      expect(wrapper.emitted('highlight')).toHaveLength(1);
    });

    it('emits clearHighlight on mouseleave', () => {
      const discussion = createDiscussion({
        position: { old_path: 'old', new_path: 'old', new_line: '1', old_line: '1' },
      });
      createComponent([discussion]);
      getDiscussionWrapper().dispatchEvent(new MouseEvent('mouseleave'));
      expect(wrapper.emitted('clear-highlight')).toHaveLength(1);
    });
  });

  describe('start another thread', () => {
    it('emits start-thread', () => {
      isLoggedIn.mockReturnValue(true);
      createComponent([createDiscussion()]);
      wrapper.findComponent(GlButton).vm.$emit('click');
      expect(wrapper.emitted('start-thread')).toHaveLength(1);
    });

    it('hides button when a form is present', () => {
      isLoggedIn.mockReturnValue(true);
      createComponent([createDiscussion(), { id: 'form-1', isForm: true }]);
      expect(wrapper.findComponent(GlButton).exists()).toBe(false);
    });

    it('shows placeholder for guests', () => {
      isLoggedIn.mockReturnValue(false);
      createComponent([createDiscussion()]);
      expect(wrapper.findComponent(NoteSignedOutWidget).exists()).toBe(true);
      expect(wrapper.findComponent(GlButton).exists()).toBe(false);
    });

    it('hides button when collapsed', () => {
      isLoggedIn.mockReturnValue(true);
      createComponent([createDiscussion()], undefined, { collapsed: true });
      expect(wrapper.findComponent(GlButton).exists()).toBe(false);
    });
  });

  describe('draft notes separation', () => {
    it('renders draft notes via DraftNote component', () => {
      const draft = createDraft();
      createComponent([draft]);
      expect(wrapper.findComponent(DraftNote).exists()).toBe(true);
      expect(wrapper.findComponent(DraftNote).props('draft')).toBe(draft.draft);
    });

    it('does not render drafts among regular discussions', () => {
      const discussion = createDiscussion();
      const draft = createDraft();
      createComponent([discussion, draft]);
      const diffDiscussions = wrapper.findComponent(DiffDiscussions);
      expect(diffDiscussions.props('discussions')).toHaveLength(1);
      expect(diffDiscussions.props('discussions')[0].isDraft).toBeUndefined();
    });

    it('shows drafts when collapsed', () => {
      const draft = createDraft();
      createComponent([draft], undefined, { collapsed: true });
      expect(wrapper.findComponent(DraftNote).exists()).toBe(true);
    });

    it('only passes draft discussions when collapsed with only drafts', () => {
      const draft = createDraft();
      createComponent([draft], undefined, { collapsed: true });
      expect(wrapper.findComponent(DiffDiscussions).exists()).toBe(false);
      expect(wrapper.findComponent(DraftNote).exists()).toBe(true);
      expect(wrapper.findComponent(GlButton).exists()).toBe(false);
    });
  });
});
