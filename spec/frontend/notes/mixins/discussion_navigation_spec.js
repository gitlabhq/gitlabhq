import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { setHTMLFixture } from 'helpers/fixtures';
import createEventHub from '~/helpers/event_hub_factory';
import * as utils from '~/lib/utils/common_utils';
import discussionNavigation from '~/notes/mixins/discussion_navigation';
import notesModule from '~/notes/stores/modules';

let scrollToFile;
const discussion = (id, index) => ({
  id,
  resolvable: index % 2 === 0,
  active: true,
  notes: [{}],
  diff_discussion: true,
  position: { new_line: 1, old_line: 1 },
  diff_file: { file_path: 'test.js' },
});
const createDiscussions = () => [...'abcde'].map(discussion);
const createComponent = () => ({
  mixins: [discussionNavigation],
  render() {
    return this.$slots.default;
  },
});

describe('Discussion navigation mixin', () => {
  Vue.use(Vuex);

  let wrapper;
  let store;
  let expandDiscussion;

  beforeEach(() => {
    setHTMLFixture(
      `<div class="tab-pane notes">
      ${[...'abcde']
        .map(
          (id) =>
            `<ul class="notes" data-discussion-id="${id}"></ul>
            <div class="discussion" data-discussion-id="${id}"></div>`,
        )
        .join('')}
      </div>`,
    );

    jest.spyOn(utils, 'scrollToElementWithContext');
    jest.spyOn(utils, 'scrollToElement');

    expandDiscussion = jest.fn();
    scrollToFile = jest.fn();
    const { actions, ...notesRest } = notesModule();
    store = new Vuex.Store({
      modules: {
        notes: {
          ...notesRest,
          actions: { ...actions, expandDiscussion },
        },
        diffs: {
          namespaced: true,
          actions: { scrollToFile, disableVirtualScroller: () => {} },
          state: { diffFiles: [] },
        },
      },
    });
    store.state.notes.discussions = createDiscussions();

    wrapper = shallowMount(createComponent(), { store });
  });

  afterEach(() => {
    wrapper.vm.$destroy();
    jest.clearAllMocks();
  });

  describe('jumpToFirstUnresolvedDiscussion method', () => {
    let vm;

    beforeEach(() => {
      createComponent();

      ({ vm } = wrapper);

      jest.spyOn(store, 'dispatch');
      jest.spyOn(vm, 'jumpToNextDiscussion');
    });

    it('triggers the setCurrentDiscussionId action with null as the value', () => {
      vm.jumpToFirstUnresolvedDiscussion();

      expect(store.dispatch).toHaveBeenCalledWith('setCurrentDiscussionId', null);
    });

    it('triggers the jumpToNextDiscussion action when the previous store action succeeds', async () => {
      store.dispatch.mockResolvedValue();

      vm.jumpToFirstUnresolvedDiscussion();

      await nextTick();
      expect(vm.jumpToNextDiscussion).toHaveBeenCalled();
    });
  });

  describe('cycle through discussions', () => {
    beforeEach(() => {
      window.mrTabs = { eventHub: createEventHub(), tabShown: jest.fn() };
    });

    describe.each`
      fn                            | args  | currentId
      ${'jumpToNextDiscussion'}     | ${[]} | ${null}
      ${'jumpToNextDiscussion'}     | ${[]} | ${'a'}
      ${'jumpToNextDiscussion'}     | ${[]} | ${'e'}
      ${'jumpToPreviousDiscussion'} | ${[]} | ${null}
      ${'jumpToPreviousDiscussion'} | ${[]} | ${'e'}
      ${'jumpToPreviousDiscussion'} | ${[]} | ${'c'}
    `('$fn (args = $args, currentId = $currentId)', ({ fn, args, currentId }) => {
      beforeEach(() => {
        store.state.notes.currentDiscussionId = currentId;
      });

      describe('on `show` active tab', () => {
        beforeEach(async () => {
          window.mrTabs.currentAction = 'show';
          wrapper.vm[fn](...args);

          await nextTick();
        });

        it('expands discussion', async () => {
          await nextTick();

          expect(expandDiscussion).toHaveBeenCalled();
        });

        it('scrolls to element', async () => {
          await nextTick();

          expect(utils.scrollToElement).toHaveBeenCalled();
        });
      });
    });
  });
});
