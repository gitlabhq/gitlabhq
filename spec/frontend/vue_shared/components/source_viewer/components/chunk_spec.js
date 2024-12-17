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

  const createComponent = (props = {}, state = {}) => {
    const store = new Vuex.Store({ state, mutations: {} });
    wrapper = shallowMountExtended(Chunk, {
      store,
      propsData: { blobPath: 'index.js', ...CHUNK_1, ...props },
    });
  };

  const findIntersectionObserver = () => wrapper.findComponent(GlIntersectionObserver);
  const findLineNumbers = () => wrapper.findAllByTestId('line-numbers');
  const findContent = () => wrapper.findByTestId('content');

  beforeEach(() => {
    createComponent();
  });

  describe('Intersection observer', () => {
    it('renders an Intersection observer component', () => {
      expect(findIntersectionObserver().exists()).toBe(true);
    });

    it('renders highlighted content if appear event is emitted', async () => {
      createComponent({ chunkIndex: 1, isHighlighted: false });
      findIntersectionObserver().vm.$emit('appear');

      await nextTick();

      expect(findContent().exists()).toBe(true);
      expect(wrapper.emitted('appear')).toHaveLength(1);
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
        { chunkIndex: 1, isHighlighted: false },
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
});
