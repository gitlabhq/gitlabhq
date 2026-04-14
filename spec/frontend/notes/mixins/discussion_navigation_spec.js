import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import createEventHub from '~/helpers/event_hub_factory';
import discussionNavigation from '~/notes/mixins/discussion_navigation';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { useDiscussions } from '~/notes/store/discussions';
import { getScrollingElement } from '~/lib/utils/panels';

jest.mock('~/lib/utils/sticky');
jest.mock('~/lib/utils/viewport', () => ({
  withHiddenTooltips: jest.fn((fn) => fn()),
}));
jest.mock('~/lib/utils/panels');

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

Vue.use(PiniaVuePlugin);

describe('Discussion navigation mixin', () => {
  let wrapper;
  let pinia;

  const createMockPanel = (overrides = {}) => ({
    getBoundingClientRect: () => ({ top: 0, bottom: 768, height: 768 }),
    scrollHeight: 2000,
    scrollTop: 0,
    clientHeight: 768,
    ...overrides,
  });

  const findDiscussionEl = (id) => document.querySelector(`div[data-discussion-id="${id}"]`);

  beforeEach(() => {
    getScrollingElement.mockReturnValue(createMockPanel());
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

    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useDiscussions().discussions = createDiscussions();
    useNotes().setCurrentDiscussionId.mockReturnValue();
    wrapper = shallowMount(createComponent(), { pinia });
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('jumpToFirstUnresolvedDiscussion method', () => {
    let vm;

    beforeEach(() => {
      createComponent();

      ({ vm } = wrapper);

      jest.spyOn(vm, 'jumpToNextDiscussion');
    });

    it('triggers the setCurrentDiscussionId action with null as the value', () => {
      vm.jumpToFirstUnresolvedDiscussion();

      expect(useNotes().setCurrentDiscussionId).toHaveBeenCalledWith(null);
    });

    it('triggers the jumpToNextDiscussion action when the previous store action succeeds', async () => {
      vm.jumpToFirstUnresolvedDiscussion();

      await nextTick();
      expect(vm.jumpToNextDiscussion).toHaveBeenCalled();
    });
  });

  describe('cycle through discussions in rapid diffs', () => {
    // Resolvable discussions: a, c, e (indices 0, 2, 4)
    // Panel top is mocked at 100
    // The rapid diffs strategy uses isScrolledTo (elementFromPoint scan)
    // and findCurrentIndex (first element with top >= panelTop)

    const panelTop = 100;
    const panelBottom = 700;
    let elementFromPointSpy;

    const setupRapidDiffs = (positions, elementFromPointFn) => {
      resetHTMLFixture();
      setHTMLFixture(
        `<div data-rapid-diffs>
          ${mockDiscussionIds
            .map(
              (id, index) =>
                `<div class="discussion" data-discussion-id="${id}" ${
                  discussion(id, index).resolvable
                    ? 'data-discussion-resolvable="true"'
                    : 'data-discussion-resolved="true"'
                }></div>`,
            )
            .join('')}
        </div>`,
      );
      window.mrTabs = {
        currentAction: 'diffs',
        eventHub: createEventHub(),
        tabShown: jest.fn(),
      };

      getScrollingElement.mockReturnValue(
        createMockPanel({
          getBoundingClientRect: () => ({
            top: panelTop,
            bottom: panelBottom,
            height: panelBottom - panelTop,
          }),
          clientHeight: 600,
        }),
      );

      mockDiscussionIds.forEach((id, index) => {
        const el = document.querySelector(`[data-rapid-diffs] div[data-discussion-id="${id}"]`);
        if (el) {
          jest.spyOn(el, 'getBoundingClientRect').mockReturnValue({
            top: positions[index],
            bottom: positions[index] + 50,
            left: 10,
            y: positions[index],
          });
          jest.spyOn(el, 'scrollIntoView').mockImplementation(() => {});
        }
      });

      elementFromPointSpy = jest.fn(elementFromPointFn || (() => null));
      document.elementFromPoint = elementFromPointSpy;

      jest.spyOn(window, 'getComputedStyle').mockReturnValue({ position: 'sticky' });

      pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
      useLegacyDiffs();
      useDiscussions().discussions = createDiscussions();
      useNotes().setCurrentDiscussionId.mockReturnValue();
      wrapper = shallowMount(createComponent(), { pinia });
    };

    describe.each`
      fn                            | positions                    | cssPosition | expectedId | description
      ${'jumpToNextDiscussion'}     | ${[200, 300, 400, 500, 600]} | ${'static'} | ${'a'}     | ${'navigates to first below panel top when not scrolled to any'}
      ${'jumpToNextDiscussion'}     | ${[105, 200, 400, 500, 600]} | ${'sticky'} | ${'c'}     | ${'navigates to next when current is scrolled to'}
      ${'jumpToNextDiscussion'}     | ${[50, 60, 70, 80, 105]}     | ${'sticky'} | ${'a'}     | ${'wraps to first when at the last one'}
      ${'jumpToNextDiscussion'}     | ${[105, 200, 108, 300, 400]} | ${'sticky'} | ${'e'}     | ${'skips same-row discussions in side-by-side diff'}
      ${'jumpToPreviousDiscussion'} | ${[50, 60, 105, 300, 400]}   | ${'sticky'} | ${'a'}     | ${'navigates to previous discussion'}
      ${'jumpToPreviousDiscussion'} | ${[105, 200, 300, 400, 500]} | ${'sticky'} | ${'e'}     | ${'wraps to last when navigating previous from first'}
      ${'jumpToPreviousDiscussion'} | ${[50, 60, 108, 300, 105]}   | ${'sticky'} | ${'a'}     | ${'skips same-row when navigating previous'}
      ${'jumpToPreviousDiscussion'} | ${[105, 200, 108, 300, 400]} | ${'sticky'} | ${'e'}     | ${'wraps to last when all previous are on the same row'}
    `('$fn - $description', ({ fn, positions, cssPosition, expectedId }) => {
      it(`expands discussion ${expectedId}`, async () => {
        const stickyEl = document.createElement('div');
        setupRapidDiffs(positions, () => stickyEl);
        jest.spyOn(window, 'getComputedStyle').mockReturnValue({ position: cssPosition });

        wrapper.vm[fn]();
        await nextTick();

        expect(useNotes().expandDiscussion).toHaveBeenCalledWith({ discussionId: expectedId });
      });
    });

    it('filters out discussions inside closed details elements', async () => {
      resetHTMLFixture();
      setHTMLFixture(
        `<div class="js-static-panel-inner" style="overflow: auto;">
          <div data-rapid-diffs>
            <div class="discussion" data-discussion-id="a" data-discussion-resolvable="true"></div>
            <details>
              <div class="discussion" data-discussion-id="c" data-discussion-resolvable="true"></div>
            </details>
            <div class="discussion" data-discussion-id="e" data-discussion-resolvable="true"></div>
          </div>
        </div>`,
      );
      window.mrTabs = {
        currentAction: 'diffs',
        eventHub: createEventHub(),
        tabShown: jest.fn(),
      };

      const panel = document.querySelector('.js-static-panel-inner');
      jest.spyOn(panel, 'getBoundingClientRect').mockReturnValue({
        top: panelTop,
        bottom: panelBottom,
        height: panelBottom - panelTop,
      });
      Object.defineProperty(panel, 'scrollHeight', { value: 2000, configurable: true });
      Object.defineProperty(panel, 'scrollTop', { value: 0, configurable: true });
      Object.defineProperty(panel, 'clientHeight', { value: 600, configurable: true });

      const positions = { a: 105, c: 200, e: 400 };
      ['a', 'c', 'e'].forEach((id) => {
        const el = document.querySelector(`div[data-discussion-id="${id}"]`);
        jest.spyOn(el, 'getBoundingClientRect').mockReturnValue({
          top: positions[id],
          bottom: positions[id] + 50,
          left: 10,
          y: positions[id],
        });
        jest.spyOn(el, 'scrollIntoView').mockImplementation(() => {});
      });

      const stickyEl = document.createElement('div');
      document.elementFromPoint = jest.fn(() => stickyEl);
      jest.spyOn(window, 'getComputedStyle').mockReturnValue({ position: 'sticky' });

      pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
      useLegacyDiffs();
      useDiscussions().discussions = createDiscussions();
      useNotes().setCurrentDiscussionId.mockReturnValue();
      wrapper = shallowMount(createComponent(), { pinia });

      wrapper.vm.jumpToNextDiscussion();
      await nextTick();

      // c is inside closed <details>, should be skipped → navigates from a to e
      expect(useNotes().expandDiscussion).toHaveBeenCalledWith({ discussionId: 'e' });
    });

    it('uses legacy strategy on overview page even with rapid diffs', async () => {
      resetHTMLFixture();
      setHTMLFixture(
        `<div data-rapid-diffs></div>
        <div class="tab-pane notes">
        ${mockDiscussionIds
          .map(
            (id, index) =>
              `<div class="discussion" data-discussion-id="${id}" ${
                discussion(id, index).resolvable
                  ? 'data-discussion-resolvable="true"'
                  : 'data-discussion-resolved="true"'
              }></div>`,
          )
          .join('')}
        </div>`,
      );
      window.mrTabs = {
        currentAction: 'show',
        eventHub: createEventHub(),
        tabShown: jest.fn(),
      };

      mockDiscussionIds.forEach((id, index) => {
        const el = document.querySelector(`.tab-pane div[data-discussion-id="${id}"]`);
        if (el) {
          jest.spyOn(el, 'getBoundingClientRect').mockReturnValue({
            top: (index + 1) * 100,
            y: (index + 1) * 100,
          });
          jest.spyOn(el, 'scrollIntoView').mockImplementation(() => {});
        }
      });

      pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
      useLegacyDiffs();
      useDiscussions().discussions = createDiscussions();
      useNotes().setCurrentDiscussionId.mockReturnValue();
      wrapper = shallowMount(createComponent(), { pinia });

      // Legacy strategy: contentTop = 0, first resolvable (a) at y=100
      // visibleOffset = 100, isActive = false → returns a
      wrapper.vm.jumpToNextDiscussion();
      await nextTick();

      expect(useNotes().expandDiscussion).toHaveBeenCalledWith({ discussionId: 'a' });
    });
  });

  describe('cycle through discussions (legacy strategy)', () => {
    // Resolvable discussions: a, c, e (indices 0, 2, 4)
    // Non-resolvable (resolved): b, d (indices 1, 3)
    // Legacy strategy uses contentTop() as the offset (mocked to 0)
    // Next: finds first resolvable with y >= contentTop, if "active" (within 2px) skips to next
    // Previous: finds index of first visible, returns index - 1, wraps to last

    const setDiscussionPositions = (positions) => {
      mockDiscussionIds.forEach((id, index) => {
        const el = findDiscussionEl(id);
        jest.spyOn(el, 'getBoundingClientRect').mockReturnValue({ y: positions[index] });
        jest.spyOn(el, 'scrollIntoView').mockImplementation(() => {});
      });
    };

    beforeEach(() => {
      window.mrTabs = { eventHub: createEventHub(), tabShown: jest.fn() };
    });

    describe.each`
      fn                            | positions                         | expectedId | description
      ${'jumpToNextDiscussion'}     | ${[100, 200, 300, 400, 500]}      | ${'a'}     | ${'picks first visible resolvable'}
      ${'jumpToNextDiscussion'}     | ${[0, 200, 100, 400, 500]}        | ${'c'}     | ${'skips active (within 2px) to next resolvable'}
      ${'jumpToNextDiscussion'}     | ${[-100, -50, -10, -5, -1]}       | ${'a'}     | ${'wraps to first when none visible'}
      ${'jumpToPreviousDiscussion'} | ${[-200, -100, 10, 400, 500]}     | ${'a'}     | ${'picks resolvable before first visible'}
      ${'jumpToPreviousDiscussion'} | ${[100, 200, 300, 400, 500]}      | ${'e'}     | ${'wraps to last when first visible is first element'}
      ${'jumpToPreviousDiscussion'} | ${[-500, -400, -300, -200, -100]} | ${'e'}     | ${'wraps to last when all above viewport'}
    `('$fn - $description', ({ fn, positions, expectedId }) => {
      describe('on `show` active tab', () => {
        beforeEach(async () => {
          window.mrTabs.currentAction = 'show';
          setDiscussionPositions(positions);

          wrapper.vm[fn]();

          await nextTick();
        });

        it('expands discussion', () => {
          expect(useNotes().expandDiscussion).toHaveBeenCalledWith({
            discussionId: expectedId,
          });
        });

        it(`scrolls to discussion element with id "${expectedId}"`, () => {
          expect(findDiscussionEl(expectedId).scrollIntoView).toHaveBeenCalledWith(true);
        });
      });
    });
  });
});
