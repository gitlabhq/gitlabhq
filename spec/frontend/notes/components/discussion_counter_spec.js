import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import notesModule from '~/notes/stores/modules';
import DiscussionCounter from '~/notes/components/discussion_counter.vue';
import { noteableDataMock, discussionMock, notesDataMock, userDataMock } from '../mock_data';
import * as types from '~/notes/stores/mutation_types';

describe('DiscussionCounter component', () => {
  let store;
  let wrapper;
  const localVue = createLocalVue();

  localVue.use(Vuex);

  beforeEach(() => {
    window.mrTabs = {};
    const { state, getters, mutations, actions } = notesModule();

    store = new Vuex.Store({
      state: {
        ...state,
        userData: userDataMock,
      },
      getters,
      mutations,
      actions,
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
      wrapper = shallowMount(DiscussionCounter, { store, localVue });

      expect(wrapper.find({ ref: 'discussionCounter' }).exists()).toBe(false);
    });
  });

  describe('has no resolvable discussions', () => {
    it('does not render', () => {
      store.commit(types.SET_INITIAL_DISCUSSIONS, [{ ...discussionMock, resolvable: false }]);
      store.dispatch('updateResolvableDiscussionsCounts');
      wrapper = shallowMount(DiscussionCounter, { store, localVue });

      expect(wrapper.find({ ref: 'discussionCounter' }).exists()).toBe(false);
    });
  });

  describe('has resolvable discussions', () => {
    const updateStore = (note = {}) => {
      discussionMock.notes[0] = { ...discussionMock.notes[0], ...note };
      store.commit(types.SET_INITIAL_DISCUSSIONS, [discussionMock]);
      store.dispatch('updateResolvableDiscussionsCounts');
    };

    afterEach(() => {
      delete discussionMock.notes[0].resolvable;
      delete discussionMock.notes[0].resolved;
    });

    it('renders', () => {
      updateStore();
      wrapper = shallowMount(DiscussionCounter, { store, localVue });

      expect(wrapper.find({ ref: 'discussionCounter' }).exists()).toBe(true);
    });

    it.each`
      title              | resolved | hasNextBtn | isActive | icon                     | groupLength
      ${'hasNextButton'} | ${false} | ${true}    | ${false} | ${'check-circle'}        | ${2}
      ${'allResolved'}   | ${true}  | ${false}   | ${true}  | ${'check-circle-filled'} | ${0}
    `('renders correctly if $title', ({ resolved, hasNextBtn, isActive, icon, groupLength }) => {
      updateStore({ resolvable: true, resolved });
      wrapper = shallowMount(DiscussionCounter, { store, localVue });

      expect(wrapper.find(`.has-next-btn`).exists()).toBe(hasNextBtn);
      expect(wrapper.find(`.is-active`).exists()).toBe(isActive);
      expect(wrapper.find({ name: icon }).exists()).toBe(true);
      expect(wrapper.findAll('[role="group"').length).toBe(groupLength);
    });
  });
});
