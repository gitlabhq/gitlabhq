import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import DiscussionCounter from '~/notes/components/discussion_counter.vue';
import * as types from '~/notes/stores/mutation_types';
import { createStore } from '~/mr_notes/stores';
import { discussionMock, noteableDataMock, notesDataMock } from '../mock_data';

describe('DiscussionCounter component', () => {
  let store;
  let wrapper;

  Vue.use(Vuex);

  beforeEach(() => {
    window.mrTabs = {};
    store = createStore();
    store.dispatch('setNoteableData', {
      ...noteableDataMock,
      create_issue_to_resolve_discussions_path: '/test',
    });
    store.dispatch('setNotesData', notesDataMock);
  });

  describe('has no discussions', () => {
    it('does not render', () => {
      wrapper = mount(DiscussionCounter, { store, propsData: { blocksMerge: true } });

      expect(wrapper.findComponent({ ref: 'discussionCounter' }).exists()).toBe(false);
    });
  });

  describe('has no resolvable discussions', () => {
    it('does not render', () => {
      store.commit(types.ADD_OR_UPDATE_DISCUSSIONS, [{ ...discussionMock, resolvable: false }]);
      store.dispatch('updateResolvableDiscussionsCounts');
      wrapper = mount(DiscussionCounter, { store, propsData: { blocksMerge: true } });

      expect(wrapper.findComponent({ ref: 'discussionCounter' }).exists()).toBe(false);
    });
  });

  describe('has resolvable discussions', () => {
    const updateStore = (note = {}) => {
      discussionMock.notes[0] = { ...discussionMock.notes[0], ...note };
      store.commit(types.ADD_OR_UPDATE_DISCUSSIONS, [discussionMock]);
      store.dispatch('updateResolvableDiscussionsCounts');
    };

    afterEach(() => {
      delete discussionMock.notes[0].resolvable;
      delete discussionMock.notes[0].resolved;
    });

    it('renders', () => {
      updateStore();
      wrapper = mount(DiscussionCounter, { store, propsData: { blocksMerge: true } });

      expect(wrapper.findComponent({ ref: 'discussionCounter' }).exists()).toBe(true);
    });

    it.each`
      blocksMerge | color
      ${true}     | ${'gl-bg-orange-50'}
      ${false}    | ${'gl-bg-strong'}
    `(
      'changes background color to $color if blocksMerge is $blocksMerge',
      ({ blocksMerge, color }) => {
        updateStore();
        store.state.notes.unresolvedDiscussionsCount = 1;
        wrapper = mount(DiscussionCounter, { store, propsData: { blocksMerge } });

        expect(wrapper.find('[data-testid="discussions-counter-text"]').classes()).toContain(color);
      },
    );

    it.each`
      title                | resolved | groupLength
      ${'not allResolved'} | ${false} | ${2}
      ${'allResolved'}     | ${true}  | ${1}
    `('renders correctly if $title', async ({ resolved, groupLength }) => {
      updateStore({ resolvable: true, resolved });
      wrapper = mount(DiscussionCounter, { store, propsData: { blocksMerge: true } });
      await wrapper.findComponent(GlDisclosureDropdown).trigger('click');

      expect(wrapper.findAllComponents(GlDisclosureDropdownItem)).toHaveLength(groupLength);
    });

    describe('resolve all with new issue link', () => {
      it('has correct href prop', async () => {
        updateStore({ resolvable: true });
        wrapper = mount(DiscussionCounter, { store, propsData: { blocksMerge: true } });

        const resolveDiscussionsPath =
          store.getters.getNoteableData.create_issue_to_resolve_discussions_path;

        await wrapper.findComponent(GlDisclosureDropdown).trigger('click');
        const resolveAllLink = wrapper.find('[data-testid="resolve-all-with-issue-link"]');

        expect(resolveAllLink.attributes('href')).toBe(resolveDiscussionsPath);
      });
    });
  });

  describe('toggle all threads button', () => {
    let toggleAllButton;
    let discussion;

    const updateStoreWithExpanded = async (expanded) => {
      discussion = { ...discussionMock, expanded };
      store.commit(types.ADD_OR_UPDATE_DISCUSSIONS, [discussion]);
      store.dispatch('updateResolvableDiscussionsCounts');
      wrapper = mount(DiscussionCounter, { store, propsData: { blocksMerge: true } });
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

      expect(store.state.notes.discussions[0].expanded).toBe(false);
    });

    it('expands all discussions if collapsed', async () => {
      await updateStoreWithExpanded(false);

      toggleAllButton.trigger('click');

      expect(store.state.notes.discussions[0].expanded).toBe(true);
    });
  });
});
