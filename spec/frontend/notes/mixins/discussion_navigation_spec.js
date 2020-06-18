import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import * as utils from '~/lib/utils/common_utils';
import discussionNavigation from '~/notes/mixins/discussion_navigation';
import eventHub from '~/notes/event_hub';
import createEventHub from '~/helpers/event_hub_factory';
import notesModule from '~/notes/stores/modules';
import { setHTMLFixture } from 'helpers/fixtures';

const discussion = (id, index) => ({
  id,
  resolvable: index % 2 === 0,
  active: true,
  notes: [{}],
  diff_discussion: true,
});
const createDiscussions = () => [...'abcde'].map(discussion);
const createComponent = () => ({
  mixins: [discussionNavigation],
  render() {
    return this.$slots.default;
  },
});

describe('Discussion navigation mixin', () => {
  const localVue = createLocalVue();
  localVue.use(Vuex);

  let wrapper;
  let store;
  let expandDiscussion;

  beforeEach(() => {
    setHTMLFixture(
      [...'abcde']
        .map(
          id =>
            `<ul class="notes" data-discussion-id="${id}"></ul>
            <div class="discussion" data-discussion-id="${id}"></div>`,
        )
        .join(''),
    );

    jest.spyOn(utils, 'scrollToElementWithContext');

    expandDiscussion = jest.fn();
    const { actions, ...notesRest } = notesModule();
    store = new Vuex.Store({
      modules: {
        notes: {
          ...notesRest,
          actions: { ...actions, expandDiscussion },
        },
      },
    });
    store.state.notes.discussions = createDiscussions();

    wrapper = shallowMount(createComponent(), { store, localVue });
  });

  afterEach(() => {
    wrapper.vm.$destroy();
    jest.clearAllMocks();
  });

  const findDiscussion = (selector, id) =>
    document.querySelector(`${selector}[data-discussion-id="${id}"]`);

  describe('cycle through discussions', () => {
    beforeEach(() => {
      window.mrTabs = { eventHub: createEventHub(), tabShown: jest.fn() };
    });

    describe.each`
      fn                                | args      | currentId | expected
      ${'jumpToNextDiscussion'}         | ${[]}     | ${null}   | ${'a'}
      ${'jumpToNextDiscussion'}         | ${[]}     | ${'a'}    | ${'c'}
      ${'jumpToNextDiscussion'}         | ${[]}     | ${'e'}    | ${'a'}
      ${'jumpToPreviousDiscussion'}     | ${[]}     | ${null}   | ${'e'}
      ${'jumpToPreviousDiscussion'}     | ${[]}     | ${'e'}    | ${'c'}
      ${'jumpToPreviousDiscussion'}     | ${[]}     | ${'c'}    | ${'a'}
      ${'jumpToNextRelativeDiscussion'} | ${[null]} | ${null}   | ${'a'}
      ${'jumpToNextRelativeDiscussion'} | ${['a']}  | ${null}   | ${'c'}
      ${'jumpToNextRelativeDiscussion'} | ${['e']}  | ${'c'}    | ${'a'}
    `('$fn (args = $args, currentId = $currentId)', ({ fn, args, currentId, expected }) => {
      beforeEach(() => {
        store.state.notes.currentDiscussionId = currentId;
      });

      describe('on `show` active tab', () => {
        beforeEach(() => {
          window.mrTabs.currentAction = 'show';
          wrapper.vm[fn](...args);
        });

        it('sets current discussion', () => {
          expect(store.state.notes.currentDiscussionId).toEqual(expected);
        });

        it('expands discussion', () => {
          expect(expandDiscussion).toHaveBeenCalled();
        });

        it('scrolls to element', () => {
          expect(utils.scrollToElementWithContext).toHaveBeenCalledWith(
            findDiscussion('div.discussion', expected),
          );
        });
      });

      describe('on `diffs` active tab', () => {
        beforeEach(() => {
          window.mrTabs.currentAction = 'diffs';
          wrapper.vm[fn](...args);
        });

        it('sets current discussion', () => {
          expect(store.state.notes.currentDiscussionId).toEqual(expected);
        });

        it('expands discussion', () => {
          expect(expandDiscussion).toHaveBeenCalled();
        });

        it('scrolls when scrollToDiscussion is emitted', () => {
          expect(utils.scrollToElementWithContext).not.toHaveBeenCalled();

          eventHub.$emit('scrollToDiscussion');

          expect(utils.scrollToElementWithContext).toHaveBeenCalledWith(
            findDiscussion('ul.notes', expected),
          );
        });
      });

      describe('on `other` active tab', () => {
        beforeEach(() => {
          window.mrTabs.currentAction = 'other';
          wrapper.vm[fn](...args);
        });

        it('sets current discussion', () => {
          expect(store.state.notes.currentDiscussionId).toEqual(expected);
        });

        it('does not expand discussion yet', () => {
          expect(expandDiscussion).not.toHaveBeenCalled();
        });

        it('shows mrTabs', () => {
          expect(window.mrTabs.tabShown).toHaveBeenCalledWith('show');
        });

        describe('when tab is changed', () => {
          beforeEach(() => {
            window.mrTabs.eventHub.$emit('MergeRequestTabChange');

            jest.runAllTimers();
          });

          it('expands discussion', () => {
            expect(expandDiscussion).toHaveBeenCalledWith(
              expect.anything(),
              {
                discussionId: expected,
              },
              undefined,
            );
          });

          it('scrolls to discussion', () => {
            expect(utils.scrollToElementWithContext).toHaveBeenCalledWith(
              findDiscussion('div.discussion', expected),
            );
          });
        });
      });
    });
  });
});
