import { getByRole } from '@testing-library/dom';
import { shallowMount, mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import DiscussionNotes from '~/notes/components/discussion_notes.vue';
import NoteableNote from '~/notes/components/noteable_note.vue';
import { SYSTEM_NOTE } from '~/notes/constants';
import PlaceholderNote from '~/vue_shared/components/notes/placeholder_note.vue';
import PlaceholderSystemNote from '~/vue_shared/components/notes/placeholder_system_note.vue';
import SystemNote from '~/vue_shared/components/notes/system_note.vue';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useNotes } from '~/notes/store/legacy_notes';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { noteableDataMock, discussionMock, notesDataMock } from '../mock_data';

jest.mock('~/behaviors/markdown/render_gfm');

const LINE_RANGE = {};
const DISCUSSION_WITH_LINE_RANGE = {
  ...discussionMock,
  position: {
    line_range: LINE_RANGE,
  },
};

Vue.use(PiniaVuePlugin);

describe('DiscussionNotes', () => {
  let pinia;
  let wrapper;

  const getList = () => getByRole(wrapper.element, 'list');
  const findNoteableNotes = () => wrapper.findAllComponents(NoteableNote);

  const createComponent = (props, mountingMethod = shallowMount) => {
    wrapper = mountingMethod(DiscussionNotes, {
      pinia,
      propsData: {
        discussion: discussionMock,
        isExpanded: false,
        shouldGroupReplies: false,
        ...props,
      },
      scopedSlots: {
        footer: `
          <template #default="{ showReplies }">
            <p>showReplies:{{ showReplies }}</p>,
          </template>
        `,
      },
      slots: {
        'avatar-badge': '<span class="avatar-badge-slot-content" />',
      },
    });
  };

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes().noteableData = noteableDataMock;
    useNotes().notesData = notesDataMock;
  });

  describe('rendering', () => {
    it('renders an element for each note in the discussion', () => {
      createComponent();
      const notesCount = discussionMock.notes.length;
      expect(findNoteableNotes()).toHaveLength(notesCount);
    });

    it('renders one element if replies groupping is enabled', () => {
      createComponent({ shouldGroupReplies: true });
      expect(findNoteableNotes()).toHaveLength(1);
    });

    it.each([
      {
        note: {
          id: 1,
          isPlaceholderNote: true,
          placeholderType: SYSTEM_NOTE,
          notes: [{ body: 'PlaceholderSystemNote' }],
        },
        component: PlaceholderSystemNote,
      },
      {
        note: {
          id: 2,
          isPlaceholderNote: true,
          notes: [{ body: 'PlaceholderNote' }],
        },
        component: PlaceholderNote,
      },
      {
        note: {
          id: 3,
          system: true,
          note: 'SystemNote',
        },
        component: SystemNote,
      },
      {
        note: discussionMock.notes[0],
        component: NoteableNote,
      },
    ])('uses $component.name to render note', ({ note, component }) => {
      createComponent({
        discussion: { ...discussionMock, notes: [note] },
      });

      expect(wrapper.findComponent(component).exists()).toBe(true);
    });

    it('renders footer scoped slot with showReplies === true when expanded', () => {
      createComponent({ isExpanded: true });
      expect(wrapper.text()).toMatch('showReplies:true');
    });

    it('renders footer scoped slot with showReplies === false when collapsed', () => {
      createComponent({ isExpanded: false });
      expect(wrapper.text()).toMatch('showReplies:false');
    });

    it('passes down avatar-badge slot content', () => {
      createComponent({}, mount);
      expect(wrapper.find('.avatar-badge-slot-content').exists()).toBe(true);
    });
  });

  describe('events', () => {
    describe('with grouped notes and replies expanded', () => {
      beforeEach(() => {
        createComponent({ shouldGroupReplies: true, isExpanded: true });
      });

      it('emits deleteNote when first note emits handleDeleteNote', async () => {
        findNoteableNotes().at(0).vm.$emit('handleDeleteNote');

        await nextTick();
        expect(wrapper.emitted().deleteNote).toHaveLength(1);
      });

      it('emits startReplying when first note emits startReplying', async () => {
        findNoteableNotes().at(0).vm.$emit('startReplying');

        await nextTick();
        expect(wrapper.emitted().startReplying).toHaveLength(1);
      });

      it('emits deleteNote when second note emits handleDeleteNote', async () => {
        findNoteableNotes().at(1).vm.$emit('handleDeleteNote');

        await nextTick();
        expect(wrapper.emitted().deleteNote).toHaveLength(1);
      });
    });

    describe('with ungroupped notes', () => {
      let note;
      beforeEach(() => {
        createComponent();
        note = wrapper.find('.notes > *');
      });

      it('emits deleteNote when first note emits handleDeleteNote', async () => {
        note.vm.$emit('handleDeleteNote');

        await nextTick();
        expect(wrapper.emitted().deleteNote).toHaveLength(1);
      });
    });
  });

  describe.each`
    desc                               | props                                         | event           | shouldSelectPosition | shouldIncludeRange
    ${'with `discussion.position`'}    | ${{ discussion: DISCUSSION_WITH_LINE_RANGE }} | ${'mouseenter'} | ${true}              | ${true}
    ${'with `discussion.position`'}    | ${{ discussion: DISCUSSION_WITH_LINE_RANGE }} | ${'mouseleave'} | ${true}              | ${false}
    ${'without `discussion.position`'} | ${{}}                                         | ${'mouseenter'} | ${false}             | ${false}
    ${'without `discussion.position`'} | ${{}}                                         | ${'mouseleave'} | ${false}             | ${false}
  `('$desc', ({ props, event, shouldSelectPosition, shouldIncludeRange }) => {
    beforeEach(() => {
      createComponent(props);
    });

    it(`calls store on ${event}`, () => {
      getList().dispatchEvent(new MouseEvent(event));
      if (shouldSelectPosition) {
        if (shouldIncludeRange) {
          expect(useNotes().setSelectedCommentPositionHover).toHaveBeenCalledWith(LINE_RANGE);
        } else {
          expect(useNotes().setSelectedCommentPositionHover).toHaveBeenCalledWith();
        }
      } else {
        expect(useNotes().setSelectedCommentPositionHover).not.toHaveBeenCalled();
      }
    });
  });

  describe('componentData', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should return first note object for placeholder note', () => {
      const data = {
        isPlaceholderNote: true,
        notes: [{ body: 'hello world!' }],
      };
      const note = wrapper.vm.componentData(data);

      expect(note).toEqual(data.notes[0]);
    });

    it('should return given note for nonplaceholder notes', () => {
      const data = {
        notes: [{ id: 12 }],
      };
      const note = wrapper.vm.componentData(data);

      expect(note).toEqual(data);
    });
  });
});
