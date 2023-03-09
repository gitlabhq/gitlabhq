import { GlDropdownItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import DiscussionCounter from '~/notes/components/discussion_counter.vue';
import notesModule from '~/notes/stores/modules';
import * as types from '~/notes/stores/mutation_types';
import { noteableDataMock, discussionMock, notesDataMock, userDataMock } from '../mock_data';

describe('DiscussionCounter component', () => {
  let store;
  let wrapper;
  let setExpandDiscussionsFn;

  Vue.use(Vuex);

  beforeEach(() => {
    window.mrTabs = {};
    const { state, getters, mutations, actions } = notesModule();
    setExpandDiscussionsFn = jest.fn().mockImplementation(actions.setExpandDiscussions);

    store = new Vuex.Store({
      state: {
        ...state,
        userData: userDataMock,
      },
      getters,
      mutations,
      actions: {
        ...actions,
        setExpandDiscussions: setExpandDiscussionsFn,
      },
    });
    store.dispatch('setNoteableData', {
      ...noteableDataMock,
      create_issue_to_resolve_discussions_path: '/test',
    });
    store.dispatch('setNotesData', notesDataMock);
  });

  afterEach(() => {
    wrapper.vm.$destroy();
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
      ${false}    | ${'gl-bg-gray-50'}
    `(
      'changes background color to $color if blocksMerge is $blocksMerge',
      ({ blocksMerge, color }) => {
        updateStore();
        store.state.unresolvedDiscussionsCount = 1;
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
      await wrapper.find('.dropdown-toggle').trigger('click');

      expect(wrapper.findAllComponents(GlDropdownItem)).toHaveLength(groupLength);
    });
  });

  describe('toggle all threads button', () => {
    let toggleAllButton;
    const updateStoreWithExpanded = async (expanded) => {
      const discussion = { ...discussionMock, expanded };
      store.commit(types.ADD_OR_UPDATE_DISCUSSIONS, [discussion]);
      store.dispatch('updateResolvableDiscussionsCounts');
      wrapper = mount(DiscussionCounter, { store, propsData: { blocksMerge: true } });
      await wrapper.find('.dropdown-toggle').trigger('click');
      toggleAllButton = wrapper.find('[data-testid="toggle-all-discussions-btn"]');
    };

    it('calls button handler when clicked', async () => {
      await updateStoreWithExpanded(true);

      toggleAllButton.trigger('click');

      expect(setExpandDiscussionsFn).toHaveBeenCalledTimes(1);
    });

    it('collapses all discussions if expanded', async () => {
      await updateStoreWithExpanded(true);

      expect(wrapper.vm.allExpanded).toBe(true);

      toggleAllButton.trigger('click');

      await nextTick();
      expect(wrapper.vm.allExpanded).toBe(false);
    });

    it('expands all discussions if collapsed', async () => {
      await updateStoreWithExpanded(false);

      expect(wrapper.vm.allExpanded).toBe(false);

      toggleAllButton.trigger('click');

      await nextTick();
      expect(wrapper.vm.allExpanded).toBe(true);
    });
  });
});
