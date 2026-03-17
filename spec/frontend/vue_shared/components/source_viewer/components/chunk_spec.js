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
        expect(findContent().text()).toBe(CHUNK_2.highlightedContent);
        expect(findContent().attributes('style')).toBe('margin-left: 96px;');
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
});
