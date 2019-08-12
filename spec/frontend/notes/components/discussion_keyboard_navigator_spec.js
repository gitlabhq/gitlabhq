/* global Mousetrap */
import 'mousetrap';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import DiscussionKeyboardNavigator from '~/notes/components/discussion_keyboard_navigator.vue';
import notesModule from '~/notes/stores/modules';

const localVue = createLocalVue();
localVue.use(Vuex);

const NEXT_ID = 'abc123';
const PREV_ID = 'def456';
const NEXT_DIFF_ID = 'abc123_diff';
const PREV_DIFF_ID = 'def456_diff';

describe('notes/components/discussion_keyboard_navigator', () => {
  let storeOptions;
  let wrapper;
  let store;

  const createComponent = (options = {}) => {
    store = new Vuex.Store(storeOptions);

    wrapper = shallowMount(DiscussionKeyboardNavigator, {
      localVue,
      store,
      ...options,
    });

    wrapper.vm.jumpToDiscussion = jest.fn();
  };

  beforeEach(() => {
    const notes = notesModule();

    notes.getters.nextUnresolvedDiscussionId = () => (currId, isDiff) =>
      isDiff ? NEXT_DIFF_ID : NEXT_ID;
    notes.getters.previousUnresolvedDiscussionId = () => (currId, isDiff) =>
      isDiff ? PREV_DIFF_ID : PREV_ID;

    storeOptions = {
      modules: {
        notes,
      },
    };
  });

  afterEach(() => {
    wrapper.destroy();
    storeOptions = null;
    store = null;
  });

  describe.each`
    isDiffView | expectedNextId  | expectedPrevId
    ${true}    | ${NEXT_DIFF_ID} | ${PREV_DIFF_ID}
    ${false}   | ${NEXT_ID}      | ${PREV_ID}
  `('when isDiffView is $isDiffView', ({ isDiffView, expectedNextId, expectedPrevId }) => {
    beforeEach(() => {
      createComponent({ propsData: { isDiffView } });
    });

    it('calls jumpToNextDiscussion when pressing `n`', () => {
      Mousetrap.trigger('n');

      expect(wrapper.vm.jumpToDiscussion).toHaveBeenCalledWith(expectedNextId);
      expect(wrapper.vm.currentDiscussionId).toEqual(expectedNextId);
    });

    it('calls jumpToPreviousDiscussion when pressing `p`', () => {
      Mousetrap.trigger('p');

      expect(wrapper.vm.jumpToDiscussion).toHaveBeenCalledWith(expectedPrevId);
      expect(wrapper.vm.currentDiscussionId).toEqual(expectedPrevId);
    });
  });
});
