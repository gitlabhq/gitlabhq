import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import DiscussionCounter from '~/notes/components/discussion_counter.vue';
import * as types from '~/notes/stores/mutation_types';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { useMrNotes } from '~/mr_notes/store/legacy_mr_notes';
import { createDiscussionMock, noteableDataMock, notesDataMock } from '../mock_data';

Vue.use(PiniaVuePlugin);

describe('DiscussionCounter component', () => {
  let pinia;
  let wrapper;

  const createComponent = (propsData) => {
    wrapper = mount(DiscussionCounter, {
      pinia,
      propsData: {
        canResolveDiscussion: true,
        ...propsData,
      },
    });
  };

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin], stubActions: false });
    useLegacyDiffs();
    useNotes();
    useMrNotes();
    window.mrTabs = {};
    useNotes().setNoteableData({
      ...noteableDataMock,
      create_issue_to_resolve_discussions_path: '/test',
    });
    useNotes().setNotesData(notesDataMock);
  });

  describe('has no discussions', () => {
    it('does not render', () => {
      createComponent({ blocksMerge: true });

      expect(wrapper.findComponent({ ref: 'discussionCounter' }).exists()).toBe(false);
    });
  });

  describe('has no resolvable discussions', () => {
    it('does not render', () => {
      useNotes()[types.ADD_OR_UPDATE_DISCUSSIONS]([
        { ...createDiscussionMock(), resolvable: false },
      ]);
      useNotes().updateResolvableDiscussionsCounts();
      createComponent({ blocksMerge: true });

      expect(wrapper.findComponent({ ref: 'discussionCounter' }).exists()).toBe(false);
    });
  });

  describe('has resolvable discussions', () => {
    const addNote = (note = {}) => {
      const discussion = createDiscussionMock();
      discussion.notes[0] = { ...discussion.notes[0], ...note };
      useNotes()[types.ADD_OR_UPDATE_DISCUSSIONS]([discussion]);
      useNotes().updateResolvableDiscussionsCounts();
    };

    it('renders', () => {
      addNote();
      createComponent({ blocksMerge: true });

      expect(wrapper.findComponent({ ref: 'discussionCounter' }).exists()).toBe(true);
    });

    it.each`
      blocksMerge | color
      ${true}     | ${'gl-bg-feedback-warning'}
      ${false}    | ${'gl-bg-strong'}
    `(
      'changes background color to $color if blocksMerge is $blocksMerge',
      ({ blocksMerge, color }) => {
        addNote();
        useNotes().unresolvedDiscussionsCount = 1;
        createComponent({ blocksMerge });

        expect(wrapper.find('[data-testid="discussions-counter-text"]').classes()).toContain(color);
      },
    );

    it.each`
      title                | resolved | groupLength
      ${'not allResolved'} | ${false} | ${2}
      ${'allResolved'}     | ${true}  | ${1}
    `('renders correctly if $title', async ({ resolved, groupLength }) => {
      addNote({ resolvable: true, resolved });
      createComponent({ blocksMerge: true });
      await wrapper.findComponent(GlDisclosureDropdown).trigger('click');

      expect(wrapper.findAllComponents(GlDisclosureDropdownItem)).toHaveLength(groupLength);
    });

    describe('resolve all with new issue link', () => {
      it('has correct href prop', async () => {
        addNote({ resolvable: true });
        createComponent({ blocksMerge: true });

        const resolveDiscussionsPath =
          useNotes().getNoteableData.create_issue_to_resolve_discussions_path;

        await wrapper.findComponent(GlDisclosureDropdown).trigger('click');
        const resolveAllLink = wrapper.find('[data-testid="resolve-all-with-issue-link"]');

        expect(resolveAllLink.attributes('href')).toBe(resolveDiscussionsPath);
      });
    });

    it('does not show resolve all with new issue link when user has no permission', async () => {
      addNote({ resolvable: true });
      createComponent({ blocksMerge: true, canResolveDiscussion: false });

      await wrapper.findComponent(GlDisclosureDropdown).trigger('click');

      expect(wrapper.find('[data-testid="resolve-all-with-issue-link"]').exists()).toBe(false);
    });
  });

  describe('toggle all threads button', () => {
    let toggleAllButton;
    let discussion;

    const updateStoreWithExpanded = async (expanded) => {
      discussion = { ...createDiscussionMock(), expanded };
      useNotes()[types.ADD_OR_UPDATE_DISCUSSIONS]([discussion]);
      useNotes().updateResolvableDiscussionsCounts();
      createComponent({ blocksMerge: true });
      await wrapper.findComponent(GlDisclosureDropdown).trigger('click');
      toggleAllButton = wrapper.find('[data-testid="toggle-all-discussions-btn"]');
    };

    afterEach(() => {
      toggleAllButton = undefined;
      discussion = undefined;
    });

    it('collapses all discussions if expanded', async () => {
      await updateStoreWithExpanded(true);

      toggleAllButton.trigger('click');

      expect(useMrNotes().toggleAllVisibleDiscussions).toHaveBeenCalled();
    });

    it('expands all discussions if collapsed', async () => {
      await updateStoreWithExpanded(false);

      toggleAllButton.trigger('click');

      expect(useMrNotes().toggleAllVisibleDiscussions).toHaveBeenCalled();
    });
  });
});
