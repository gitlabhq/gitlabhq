import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
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
    wrapper = null;
  });

  describe('has no discussions', () => {
    it('does not render', () => {
      wrapper = shallowMount(DiscussionCounter, { store, propsData: { blocksMerge: true } });

      expect(wrapper.findComponent({ ref: 'discussionCounter' }).exists()).toBe(false);
    });
  });

  describe('has no resolvable discussions', () => {
    it('does not render', () => {
      store.commit(types.ADD_OR_UPDATE_DISCUSSIONS, [{ ...discussionMock, resolvable: false }]);
      store.dispatch('updateResolvableDiscussionsCounts');
      wrapper = shallowMount(DiscussionCounter, { store, propsData: { blocksMerge: true } });

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
      wrapper = shallowMount(DiscussionCounter, { store, propsData: { blocksMerge: true } });

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
        wrapper = shallowMount(DiscussionCounter, { store, propsData: { blocksMerge } });

        expect(wrapper.find('[data-testid="discussions-counter-text"]').classes()).toContain(color);
      },
    );

    it.each`
      title                | resolved | groupLength
      ${'not allResolved'} | ${false} | ${4}
      ${'allResolved'}     | ${true}  | ${1}
    `('renders correctly if $title', ({ resolved, groupLength }) => {
      updateStore({ resolvable: true, resolved });
      wrapper = shallowMount(DiscussionCounter, { store, propsData: { blocksMerge: true } });

      expect(wrapper.findAllComponents(GlButton)).toHaveLength(groupLength);
    });
  });

  describe('toggle all threads button', () => {
    let toggleAllButton;
    const updateStoreWithExpanded = (expanded) => {
      const discussion = { ...discussionMock, expanded };
      store.commit(types.ADD_OR_UPDATE_DISCUSSIONS, [discussion]);
      store.dispatch('updateResolvableDiscussionsCounts');
      wrapper = shallowMount(DiscussionCounter, { store, propsData: { blocksMerge: true } });
      toggleAllButton = wrapper.find('.toggle-all-discussions-btn');
    };

    afterEach(() => wrapper.destroy());

    it('calls button handler when clicked', () => {
      updateStoreWithExpanded(true);

      toggleAllButton.vm.$emit('click');

      expect(setExpandDiscussionsFn).toHaveBeenCalledTimes(1);
    });

    it('collapses all discussions if expanded', async () => {
      updateStoreWithExpanded(true);

      expect(wrapper.vm.allExpanded).toBe(true);
      expect(toggleAllButton.props('icon')).toBe('collapse');

      toggleAllButton.vm.$emit('click');

      await nextTick();
      expect(wrapper.vm.allExpanded).toBe(false);
      expect(toggleAllButton.props('icon')).toBe('expand');
    });

    it('expands all discussions if collapsed', async () => {
      updateStoreWithExpanded(false);

      expect(wrapper.vm.allExpanded).toBe(false);
      expect(toggleAllButton.props('icon')).toBe('expand');

      toggleAllButton.vm.$emit('click');

      await nextTick();
      expect(wrapper.vm.allExpanded).toBe(true);
      expect(toggleAllButton.props('icon')).toBe('collapse');
    });
  });
});
