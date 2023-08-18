import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import createEventHub from '~/helpers/event_hub_factory';
import * as utils from '~/lib/utils/common_utils';
import discussionNavigation from '~/notes/mixins/discussion_navigation';
import notesModule from '~/notes/stores/modules';

let scrollToFile;
const discussion = (id, index) => ({
  id,
  resolvable: index % 2 === 0, // discussions 'b' and 'd' are not resolvable
  active: true,
  notes: [{}],
  diff_discussion: true,
  position: { new_line: 1, old_line: 1 },
  diff_file: { file_path: 'test.js' },
});
const mockDiscussionIds = [...'abcde'];
const createDiscussions = () => mockDiscussionIds.map(discussion);
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

  const findDiscussionEl = (id) => document.querySelector(`div[data-discussion-id="${id}"]`);

  beforeEach(() => {
    setHTMLFixture(
      `<div class="tab-pane notes">
      ${mockDiscussionIds
        .map(
          (id, index) =>
            `<ul class="notes" data-discussion-id="${id}"></ul>
            <div class="discussion" data-discussion-id="${id}" ${
              discussion(id, index).resolvable
                ? 'data-discussion-resolvable="true"'
                : 'data-discussion-resolved="true"'
            }></div>`,
        )
        .join('')}
      </div>`,
    );

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
    resetHTMLFixture();
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

      // Since we cannot actually scroll on the window, we have to mock each
      // discussion's `getBoundingClientRect` to replicate the scroll position:
      // a is at 100, b is at 200, c is at 300, d is at 400, e is at 500.
      mockDiscussionIds.forEach((id, index) => {
        jest
          .spyOn(findDiscussionEl(id), 'getBoundingClientRect')
          .mockReturnValue({ y: (index + 1) * 100 });
      });

      jest.spyOn(utils, 'scrollToElement');
    });

    describe.each`
      fn                            | currentScrollPosition | expectedId
      ${'jumpToNextDiscussion'}     | ${null}               | ${'a'}
      ${'jumpToNextDiscussion'}     | ${100}                | ${'c'}
      ${'jumpToNextDiscussion'}     | ${200}                | ${'c'}
      ${'jumpToNextDiscussion'}     | ${500}                | ${'a'}
      ${'jumpToPreviousDiscussion'} | ${null}               | ${'e'}
      ${'jumpToPreviousDiscussion'} | ${100}                | ${'e'}
      ${'jumpToPreviousDiscussion'} | ${200}                | ${'a'}
      ${'jumpToPreviousDiscussion'} | ${500}                | ${'c'}
    `(
      '$fn (currentScrollPosition = $currentScrollPosition)',
      ({ fn, currentScrollPosition, expectedId }) => {
        describe('on `show` active tab', () => {
          beforeEach(async () => {
            window.mrTabs.currentAction = 'show';

            // Set `document.body.scrollHeight` higher than `window.innerHeight` (which is 768)
            // to prevent `hasReachedPageEnd` from always returning true
            jest.spyOn(document.body, 'scrollHeight', 'get').mockReturnValue(1000);
            // Mock current scroll position
            jest.spyOn(utils, 'contentTop').mockReturnValue(currentScrollPosition);

            wrapper.vm[fn]();

            await nextTick();
          });

          it('expands discussion', () => {
            expect(expandDiscussion).toHaveBeenCalledWith(expect.any(Object), {
              discussionId: expectedId,
            });
          });

          it(`scrolls to discussion element with id "${expectedId}"`, () => {
            expect(utils.scrollToElement).toHaveBeenLastCalledWith(
              findDiscussionEl(expectedId),
              undefined,
            );
          });
        });
      },
    );
  });
});
