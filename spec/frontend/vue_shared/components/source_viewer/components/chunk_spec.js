// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import Vue, { nextTick } from 'vue';
import { GlIntersectionObserver } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Chunk from '~/vue_shared/components/source_viewer/components/chunk.vue';
import { addInteractionClass } from '~/code_navigation/utils';
import { CHUNK_1, CHUNK_2 } from '../mock_data';

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

    it('emits highlighted when shouldHighlight transitions to true', async () => {
      createComponent({ ...CHUNK_2, isHighlighted: false });
      expect(wrapper.emitted('highlighted')).toBeUndefined();

      await wrapper.setProps({ isHighlighted: true });
      await nextTick();

      expect(wrapper.emitted('highlighted')).toHaveLength(1);
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
        expect(findHighlightOverlay().attributes('style')).toBe('margin-left: 96px;');
      });
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
