// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import Vue, { nextTick } from 'vue';
import { GlIntersectionObserver } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Chunk from '~/vue_shared/components/source_viewer/components/chunk.vue';
import BlameCommitInfo from '~/vue_shared/components/source_viewer/components/blame_commit_info.vue';
import BlameSkeletonLoader from '~/vue_shared/components/source_viewer/components/blame_skeleton_loader.vue';
import { addInteractionClass } from '~/code_navigation/utils';
import { CHUNK_1, CHUNK_2, CHUNK_BLAME_GROUPS_MOCK } from '../mock_data';

jest.mock('~/code_navigation/utils');

Vue.use(Vuex);

describe('Chunk component', () => {
  let wrapper;
  let mockBlameActions;

  const createComponent = (props = {}, state = {}, featureFlags = {}) => {
    const store = new Vuex.Store({ state, mutations: {} });
    wrapper = shallowMountExtended(Chunk, {
      store,
      propsData: {
        blobPath: 'index.js',
        blamePath: '/project/blame/main/index.js',
        pageSearchString: '?ref=main',
        ...CHUNK_1,
        ...props,
      },
      provide: {
        blameActions: mockBlameActions,
        glFeatures: {
          inlineBlame: false,
          ...featureFlags,
        },
      },
    });
  };

  const findIntersectionObserver = () => wrapper.findComponent(GlIntersectionObserver);
  const findLineNumbers = () => wrapper.findAllByTestId('line-numbers');
  const findContent = () => wrapper.findByTestId('content');
  const findBlameLink = (lineNumber = 1) => wrapper.findByTestId(`blame-link-${lineNumber}`);
  const findHighlightOverlay = () => wrapper.find('code[inert]');

  beforeEach(() => {
    mockBlameActions = {
      activateInlineBlame: jest.fn(),
    };
  });

  describe('Intersection observer', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders an Intersection observer component', () => {
      expect(findIntersectionObserver().exists()).toBe(true);
    });

    it('emits appear event when intersection observer appears', async () => {
      createComponent({ isHighlighted: false });
      findIntersectionObserver().vm.$emit('appear');

      await nextTick();

      expect(findContent().exists()).toBe(true);
      expect(wrapper.emitted('appear')).toHaveLength(1);
    });

    it('emits disappear event when intersection observer disappears', () => {
      findIntersectionObserver().vm.$emit('disappear');

      expect(wrapper.emitted('disappear')).toHaveLength(1);
    });
  });

  describe('rendering', () => {
    describe('isHighlighted is false', () => {
      beforeEach(() => createComponent(CHUNK_2));

      it('does not render line numbers', () => {
        expect(findLineNumbers()).toHaveLength(0);
      });

      it('renders raw content', () => {
        expect(findContent().text()).toBe(CHUNK_2.rawContent);
      });
    });

    describe('isHighlighted is true', () => {
      beforeEach(() => createComponent({ ...CHUNK_2, isHighlighted: true }));

      it('renders line numbers', () => {
        expect(findLineNumbers()).toHaveLength(CHUNK_2.totalLines);

        // Opted for a snapshot test here since the output is simple and verifies native HTML elements
        expect(findLineNumbers().at(0).element).toMatchSnapshot();
      });

      it('renders highlighted content', () => {
        expect(findHighlightOverlay().exists()).toBe(true);
      });

      it('does not offset the overlay by a measured gutter width', () => {
        // The gutter is a real grid column now, so the overlay no longer needs a
        // margin derived from the line-number element's width.
        expect(findHighlightOverlay().attributes('style')).toBeUndefined();
      });
    });
  });

  describe('line hover', () => {
    const firstLineNumber = CHUNK_2.startingFrom + 1;
    const findRawLayer = () => wrapper.find('code[data-testid="content"]:not([inert])');

    // Resolve the hovered code line via the overlay, mirroring how the component
    // uses `document.elementsFromPoint` (not implemented in jsdom).
    const hoverCodeLine = async (lineNumber) => {
      const overlay = findHighlightOverlay().element;
      const lineEl = document.createElement('span');
      lineEl.classList.add('line');
      lineEl.id = `LC${lineNumber}`;
      overlay.appendChild(lineEl);
      document.elementsFromPoint.mockReturnValue([lineEl]);
      await findRawLayer().trigger('mousemove');
    };

    beforeEach(() => {
      document.elementsFromPoint = jest.fn().mockReturnValue([]);
      // Run the rAF-throttled hover hit-test synchronously.
      jest.spyOn(window, 'requestAnimationFrame').mockImplementation((cb) => cb());
      createComponent({ ...CHUNK_2, isHighlighted: true });
    });

    afterEach(() => {
      delete document.elementsFromPoint;
      window.requestAnimationFrame.mockRestore();
    });

    it('tints the gutter cell of the hovered code line with is-over', async () => {
      await hoverCodeLine(firstLineNumber);

      expect(findLineNumbers().at(0).classes()).toContain('is-over');
    });

    it('moves the tint as different code lines are hovered', async () => {
      await hoverCodeLine(firstLineNumber);
      expect(findLineNumbers().at(0).classes()).toContain('is-over');

      await hoverCodeLine(firstLineNumber + 1);
      expect(findLineNumbers().at(0).classes()).not.toContain('is-over');
      expect(findLineNumbers().at(1).classes()).toContain('is-over');
    });

    it('clears the tint when the pointer leaves the code', async () => {
      await hoverCodeLine(firstLineNumber);
      expect(findLineNumbers().at(0).classes()).toContain('is-over');

      await findRawLayer().trigger('mouseleave');

      expect(findLineNumbers().at(0).classes()).not.toContain('is-over');
    });
  });

  describe('with code navigation', () => {
    it('adds code navigation data to current rendered chunks', async () => {
      createComponent({}, { blobs: ['index.js'], data: { 'index.js': { '0:1': 'test' } } });

      await nextTick();

      expect(addInteractionClass).toHaveBeenCalledWith({ d: 'test', path: 'index.js' });
    });

    it('adds code navigation data to newly rendered chunks', async () => {
      createComponent(
        { isHighlighted: false },
        { blobs: ['index.js'], data: { 'index.js': { '0:1': 'test' } } },
      );

      findIntersectionObserver().vm.$emit('appear');

      // `nextTick` here for data watcher
      await nextTick();

      // `nextTick` here for `nextTick` in the component
      await nextTick();

      expect(addInteractionClass).toHaveBeenCalledWith({ d: 'test', path: 'index.js' });
    });
  });

  describe('Chunk blame link visibility', () => {
    it('hides blame link when blame is active', () => {
      createComponent({ isBlameActive: true });

      expect(findBlameLink(1).exists()).toBe(false);
    });

    it('shows blame link when blame is not active', () => {
      createComponent({ isBlameActive: false });

      expect(findBlameLink(1).exists()).toBe(true);
    });
  });

  describe('Chunk blame functionality', () => {
    describe('with feature flag enabled', () => {
      it('prevents default and activates inline blame when blame link is clicked', () => {
        createComponent({ isBlameActive: false }, {}, { inlineBlame: true });

        const mockEvent = { preventDefault: jest.fn() };

        wrapper.vm.handleBlameClick(mockEvent, 0);

        expect(mockEvent.preventDefault).toHaveBeenCalled();
        expect(mockBlameActions.activateInlineBlame).toHaveBeenCalledWith(1);
      });
    });

    describe('with feature flag disabled', () => {
      it('allows default navigation when blame link is clicked', () => {
        createComponent({ isBlameActive: false }, {}, { inlineBlame: false });

        const mockEvent = { preventDefault: jest.fn() };

        wrapper.vm.handleBlameClick(mockEvent, 0);

        expect(mockEvent.preventDefault).not.toHaveBeenCalled();
        expect(mockBlameActions.activateInlineBlame).not.toHaveBeenCalled();
      });

      it('renders blame link with correct href attribute', () => {
        const blamePath = '/project/blame/main/index.js';
        createComponent({
          isBlameActive: false,
          blamePath,
        });

        const actualHref = findBlameLink(1).attributes('href');
        expect(actualHref).toBe(`${blamePath}${wrapper.vm.pageSearchString}#L1`);
      });
    });
  });

  describe('blame rendering', () => {
    const findBlameCells = () => wrapper.findAllByTestId('blame-cell');
    const findBlameSeparators = () => wrapper.findAllByTestId('blame-separator');
    const findGutterSeparators = () => wrapper.findAllByTestId('blame-separator-gutter');
    const findSkeletonLoader = () => wrapper.findComponent(BlameSkeletonLoader);
    const findCommitInfos = () => wrapper.findAllComponents(BlameCommitInfo);

    const createWithBlame = (props = {}) =>
      createComponent({
        isBlameActive: true,
        blameGroups: CHUNK_BLAME_GROUPS_MOCK,
        ...props,
      });

    it('renders no blame cells when blame is inactive', () => {
      createWithBlame({ isBlameActive: false });

      expect(findBlameCells()).toHaveLength(0);
    });

    it('renders a blame cell per group when blame is active', () => {
      createWithBlame();

      expect(findBlameCells()).toHaveLength(2);
    });

    it('passes each group commit through to BlameCommitInfo', () => {
      createWithBlame();

      expect(findCommitInfos().at(0).props()).toMatchObject({
        commit: CHUNK_BLAME_GROUPS_MOCK[0].commit,
        previousPath: CHUNK_BLAME_GROUPS_MOCK[0].previousPath,
      });
    });

    describe('screen reader line range', () => {
      const findCellLines = (index) => wrapper.findAllByTestId('blame-cell-lines').at(index).text();

      it('labels a multi-line group with its line range', () => {
        createWithBlame();

        expect(findCellLines(0)).toBe('Lines 1 to 2');
      });

      it('labels a single-line group with one line number', () => {
        createWithBlame();

        expect(findCellLines(1)).toBe('Line 3');
      });

      it('offsets the range by the chunk start', () => {
        createWithBlame({ startingFrom: 70 });

        expect(findCellLines(0)).toBe('Lines 71 to 72');
      });

      it('labels a group carried over from the previous chunk with the lines it renders', () => {
        // Group opens at line 65, but this chunk starts at 71, so the cell is
        // clamped to lines 71-74 even though `lineno` still reads 65.
        createWithBlame({
          startingFrom: 70,
          blameGroups: [
            { ...CHUNK_BLAME_GROUPS_MOCK[0], lineno: 65, span: 10, rowStart: 1, rowSpan: 4 },
          ],
        });

        expect(findCellLines(0)).toBe('Lines 71 to 74');
      });
    });

    describe('grid placement', () => {
      it('places a group in the blame column across exactly the rows it spans', () => {
        createWithBlame();
        const cell = findBlameCells().at(0);

        expect(cell.classes()).toContain('gl-col-start-1');
        expect(cell.element.style.gridRowStart).toBe('1');
        // rowStart 1 + rowSpan 2 -> ends before row 3
        expect(cell.element.style.gridRowEnd).toBe('3');
      });

      it('places a single-line group on one row', () => {
        createWithBlame();
        const { style } = findBlameCells().at(1).element;

        expect(style.gridRowStart).toBe('3');
        expect(style.gridRowEnd).toBe('4');
      });

      const findAgeColor = (index) =>
        findBlameCells().at(index).element.style.getPropertyValue('--blame-age-color');

      it('colours the age indicator from the commit age bucket', () => {
        createWithBlame();

        expect(findAgeColor(0)).toBe('var(--gl-color-data-blue-50)'); // blame-commit-age-9
        expect(findAgeColor(1)).toBe('var(--gl-color-data-blue-900)'); // blame-commit-age-0
      });

      it('falls back to a transparent indicator when age data is missing', () => {
        createWithBlame({
          blameGroups: [{ ...CHUNK_BLAME_GROUPS_MOCK[0], commitData: undefined }],
        });

        expect(findAgeColor(0)).toBe('transparent');
      });
    });

    describe('group separators', () => {
      it('draws a separator only for the groups flagged for one', () => {
        createWithBlame();

        expect(findBlameSeparators()).toHaveLength(1);
      });

      it('draws a separator for a flagged group', () => {
        createWithBlame({
          blameGroups: [{ ...CHUNK_BLAME_GROUPS_MOCK[0], rowStart: 1, hasSeparator: true }],
        });

        expect(findBlameSeparators()).toHaveLength(1);
      });

      it('draws no separator for an unflagged group', () => {
        createWithBlame({
          blameGroups: [{ ...CHUNK_BLAME_GROUPS_MOCK[0], rowStart: 1, hasSeparator: false }],
        });

        expect(findBlameSeparators()).toHaveLength(0);
      });

      it('draws a matching separator half in the gutter column', () => {
        createWithBlame();

        expect(findGutterSeparators()).toHaveLength(1);
        expect(findGutterSeparators().at(0).element.style.gridRow).toBe('3');
      });

      it('spans the code separator across the line-number and code columns', () => {
        createWithBlame();
        const separator = findBlameSeparators().at(0);

        expect(separator.classes()).toContain('gl-col-start-2');
        expect(separator.classes()).toContain('gl-col-span-2');
        expect(separator.element.style.gridRow).toBe('3');
      });

      it('draws the code separator before the gutter half so the gutter half paints over it', () => {
        createWithBlame();
        const halves = wrapper.findAll(
          '[data-testid="blame-separator"], [data-testid="blame-separator-gutter"]',
        );

        expect(halves.at(0).attributes('data-testid')).toBe('blame-separator');
        expect(halves.at(1).attributes('data-testid')).toBe('blame-separator-gutter');
        expect(halves.at(0).classes()).toContain('gl-z-4');
        expect(halves.at(1).classes()).toContain('gl-z-4');
      });
    });

    describe('skeleton loader', () => {
      it('shows while the chunk is fetching and has no groups yet', () => {
        createWithBlame({ blameGroups: [], isBlameLoading: true });

        expect(findSkeletonLoader().exists()).toBe(true);
        expect(findSkeletonLoader().props()).toMatchObject({
          startLine: CHUNK_1.startingFrom,
          totalLines: CHUNK_1.totalLines,
        });
      });

      it('hides once the groups for the chunk have arrived', () => {
        createWithBlame({ isBlameLoading: true });

        expect(findSkeletonLoader().exists()).toBe(false);
      });

      it('hides when blame is inactive', () => {
        createWithBlame({ isBlameActive: false, blameGroups: [], isBlameLoading: true });

        expect(findSkeletonLoader().exists()).toBe(false);
      });
    });
  });

  describe('two-layer rendering (Ctrl+F fix)', () => {
    const findRawLayer = () => wrapper.find('code[data-testid="content"]:not([inert])');

    beforeEach(() => {
      document.elementsFromPoint = jest.fn().mockReturnValue([]);
    });

    afterEach(() => {
      delete document.elementsFromPoint;
    });

    describe('raw layer', () => {
      it.each([{ isHighlighted: false }, { isHighlighted: true }])(
        'always renders raw content layer when isHighlighted is $isHighlighted',
        ({ isHighlighted }) => {
          createComponent({ ...CHUNK_2, isHighlighted });
          expect(findRawLayer().exists()).toBe(true);
          expect(findRawLayer().text()).toBe(CHUNK_2.rawContent);
        },
      );

      it('renders raw layer with transparent text so it is invisible to the user', () => {
        createComponent(CHUNK_2);
        expect(findRawLayer().classes()).toContain('!gl-text-transparent');
      });

      it('pins raw layer min-height to totalLines so the overlay cannot overhang', () => {
        createComponent(CHUNK_2);
        expect(findRawLayer().attributes('style')).toContain(
          `min-height: calc(${CHUNK_2.totalLines} * var(--source-line-height))`,
        );
      });
    });

    describe('highlighted overlay layer', () => {
      it.each([
        { isHighlighted: false, shouldExist: false },
        { isHighlighted: true, shouldExist: true },
      ])(
        'highlight overlay exists: $shouldExist when isHighlighted is $isHighlighted',
        ({ isHighlighted, shouldExist }) => {
          createComponent({ ...CHUNK_2, isHighlighted });
          expect(findHighlightOverlay().exists()).toBe(shouldExist);
        },
      );

      it('marks the highlighted overlay as inert so browser find skips it', () => {
        createComponent({ ...CHUNK_2, isHighlighted: true });
        expect(findHighlightOverlay().attributes('inert')).toBeDefined();
      });

      it('marks the highlighted overlay with data-gfm-ignore so CopyAsGFM excludes it from copied selections', () => {
        createComponent({ ...CHUNK_2, isHighlighted: true });
        expect(findHighlightOverlay().attributes('data-gfm-ignore')).toBeDefined();
      });

      it('positions the highlighted overlay absolutely so it overlays the raw layer', () => {
        createComponent({ ...CHUNK_2, isHighlighted: true });
        expect(findHighlightOverlay().classes()).toContain('gl-absolute');
      });
    });

    describe('forwardEventToHighlight', () => {
      const mockClientX = 100;
      const mockClientY = 200;

      beforeEach(() => {
        createComponent({ ...CHUNK_2, isHighlighted: true });
      });

      it('temporarily removes inert, dispatches event on target, then restores inert', () => {
        const overlay = findHighlightOverlay().element;
        const mockTarget = document.createElement('span');
        overlay.appendChild(mockTarget);

        document.elementsFromPoint.mockReturnValue([mockTarget]);
        const dispatchSpy = jest.spyOn(mockTarget, 'dispatchEvent');

        wrapper.vm.forwardEventToHighlight({
          type: 'click',
          clientX: mockClientX,
          clientY: mockClientY,
        });

        expect(dispatchSpy).toHaveBeenCalledWith(
          expect.objectContaining({
            type: 'click',
            bubbles: true,
            clientX: mockClientX,
            clientY: mockClientY,
          }),
        );
        expect(overlay.hasAttribute('inert')).toBe(true);
      });

      it('does nothing if the highlighted overlay ref is not present', () => {
        createComponent({ ...CHUNK_2, isHighlighted: false });
        expect(() => {
          wrapper.vm.forwardEventToHighlight({ type: 'click', clientX: 0, clientY: 0 });
        }).not.toThrow();
      });

      it('does nothing if no element from the overlay is found at the coordinates', () => {
        document.elementsFromPoint.mockReturnValue([]);
        expect(() => {
          wrapper.vm.forwardEventToHighlight({
            type: 'click',
            clientX: mockClientX,
            clientY: mockClientY,
          });
        }).not.toThrow();
      });

      it('restores inert even if no target element is found', () => {
        const overlay = findHighlightOverlay().element;
        document.elementsFromPoint.mockReturnValue([]);

        wrapper.vm.forwardEventToHighlight({
          type: 'click',
          clientX: mockClientX,
          clientY: mockClientY,
        });

        expect(overlay.hasAttribute('inert')).toBe(true);
      });
    });

    describe('raw layer pointer event forwarding', () => {
      beforeEach(() => {
        createComponent({ ...CHUNK_2, isHighlighted: true });
      });

      it('forwards click events from raw layer to highlighted overlay', async () => {
        await findRawLayer().trigger('click');
        expect(document.elementsFromPoint).toHaveBeenCalled();
      });

      it('forwards mouseover events from raw layer to highlighted overlay', async () => {
        await findRawLayer().trigger('mouseover');
        expect(document.elementsFromPoint).toHaveBeenCalled();
      });

      it('forwards mouseout events from raw layer to highlighted overlay', async () => {
        await findRawLayer().trigger('mouseout');
        expect(document.elementsFromPoint).toHaveBeenCalled();
      });
    });
  });
});
