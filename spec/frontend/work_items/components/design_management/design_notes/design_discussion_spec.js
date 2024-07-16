import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DesignDiscussion from '~/work_items/components/design_management/design_notes/design_discussion.vue';
import DesignNote from '~/work_items/components/design_management/design_notes/design_note.vue';
import ToggleRepliesWidget from '~/work_items/components/design_management/design_notes/toggle_replies_widget.vue';
import notes from './mock_notes';

const defaultMockDiscussion = {
  id: '0',
  resolved: false,
  resolvable: true,
  notes,
};

describe('Design discussions component', () => {
  let wrapper;

  const findDesignNotes = () => wrapper.findAllComponents(DesignNote);
  const findRepliesWidget = () => wrapper.findComponent(ToggleRepliesWidget);
  const findResolveButton = () => wrapper.find('[data-testid="resolve-button"]');
  const findResolvedMessage = () => wrapper.find('[data-testid="resolved-message"]');

  function createComponent({ props = {}, data = {} } = {}) {
    wrapper = mount(DesignDiscussion, {
      propsData: {
        discussion: defaultMockDiscussion,
        ...props,
      },
      data() {
        return {
          ...data,
        };
      },
      mocks: {
        $route: {
          hash: '#note_1',
          params: {
            id: 1,
          },
          query: {
            version: null,
          },
        },
      },
    });
  }

  beforeEach(() => {
    window.gon = { current_user_id: 1 };
  });

  describe('when discussion is not resolvable', () => {
    beforeEach(() => {
      createComponent({
        props: {
          discussion: {
            ...defaultMockDiscussion,
            resolvable: false,
          },
        },
      });
    });

    it('does not render an icon to resolve a thread', () => {
      expect(findResolveButton().exists()).toBe(false);
    });
  });

  describe('when discussion is unresolved', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders correct amount of discussion notes', () => {
      expect(findDesignNotes()).toHaveLength(2);
      expect(findDesignNotes().wrappers.every((w) => w.isVisible())).toBe(true);
    });

    it('renders toggle replies widget', () => {
      expect(findRepliesWidget().exists()).toBe(true);
    });

    it('renders a correct icon to resolve a thread', () => {
      expect(findResolveButton().props('icon')).toBe('check-circle');
    });

    it('does not render resolved message', () => {
      expect(findResolvedMessage().exists()).toBe(false);
    });

    it('renders toggle replies widget with correct props', () => {
      expect(findRepliesWidget().exists()).toBe(true);
      expect(findRepliesWidget().props()).toEqual({
        collapsed: false,
        replies: notes.slice(1),
      });
    });
  });

  describe('when discussion is resolved', () => {
    beforeEach(() => {
      createComponent({
        props: {
          discussion: {
            ...defaultMockDiscussion,
            resolved: true,
            resolvedBy: notes[0].author,
            resolvedAt: '2020-05-08T07:10:45Z',
          },
        },
      });
    });

    it('shows only the first note', () => {
      expect(findDesignNotes().at(0).isVisible()).toBe(true);
      expect(findDesignNotes().at(1).isVisible()).toBe(false);
    });

    it('renders resolved message', () => {
      expect(findResolvedMessage().exists()).toBe(true);
    });

    it('renders toggle replies widget with correct props', () => {
      expect(findRepliesWidget().exists()).toBe(true);
      expect(findRepliesWidget().props()).toEqual({
        collapsed: true,
        replies: notes.slice(1),
      });
    });

    it('renders a correct icon to resolve a thread', () => {
      expect(findResolveButton().props('icon')).toBe('check-circle-filled');
    });

    describe('when replies are expanded', () => {
      beforeEach(async () => {
        findRepliesWidget().vm.$emit('toggle');
        await nextTick();
      });

      it('renders replies widget with collapsed prop equal to false', () => {
        expect(findRepliesWidget().props('collapsed')).toBe(false);
      });

      it('renders the second note', () => {
        expect(findDesignNotes().at(1).isVisible()).toBe(true);
      });
    });
  });

  it('does not render toggle replies widget if there are no threads', () => {
    createComponent({
      props: {
        discussion: {
          id: 'gid://gitlab/Discussion/fac4739884a66ebe979480dab8a7cc151f9ab63a',
          notes: [{ ...notes[0], notes: [] }],
        },
      },
    });
    expect(findRepliesWidget().exists()).toBe(false);
  });
});
