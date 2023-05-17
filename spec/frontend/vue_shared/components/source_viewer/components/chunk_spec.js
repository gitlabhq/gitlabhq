import { nextTick } from 'vue';
import { GlIntersectionObserver } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Chunk from '~/vue_shared/components/source_viewer/components/chunk.vue';
import { CHUNK_1, CHUNK_2 } from '../mock_data';

describe('Chunk component', () => {
  let wrapper;
  let idleCallbackSpy;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(Chunk, {
      propsData: { ...CHUNK_1, ...props },
    });
  };

  const findIntersectionObserver = () => wrapper.findComponent(GlIntersectionObserver);
  const findLineNumbers = () => wrapper.findAllByTestId('line-numbers');
  const findContent = () => wrapper.findByTestId('content');

  beforeEach(() => {
    idleCallbackSpy = jest.spyOn(window, 'requestIdleCallback').mockImplementation((fn) => fn());
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
    });
  });

  describe('rendering', () => {
    it('does not register window.requestIdleCallback for the first chunk, renders content immediately', () => {
      jest.clearAllMocks();

      expect(window.requestIdleCallback).not.toHaveBeenCalled();
      expect(findContent().text()).toBe(CHUNK_1.highlightedContent);
    });

    it('does not render content if browser is not in idle state', () => {
      idleCallbackSpy.mockRestore();
      createComponent({ chunkIndex: 1, ...CHUNK_2 });

      expect(findLineNumbers()).toHaveLength(0);
      expect(findContent().exists()).toBe(false);
    });

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
      });
    });
  });
});
