import { GlIntersectionObserver } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Chunk from '~/vue_shared/components/source_viewer/components/chunk.vue';
import ChunkLine from '~/vue_shared/components/source_viewer/components/chunk_line.vue';

const DEFAULT_PROPS = {
  chunkIndex: 2,
  isHighlighted: false,
  content: '// Line 1 content \n // Line 2 content',
  startingFrom: 140,
  totalLines: 50,
  language: 'javascript',
};

describe('Chunk component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(Chunk, { propsData: { ...DEFAULT_PROPS, ...props } });
  };

  const findIntersectionObserver = () => wrapper.findComponent(GlIntersectionObserver);
  const findChunkLines = () => wrapper.findAllComponents(ChunkLine);
  const findLineNumbers = () => wrapper.findAllByTestId('line-number');
  const findContent = () => wrapper.findByTestId('content');

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => wrapper.destroy());

  describe('Intersection observer', () => {
    it('renders an Intersection observer component', () => {
      expect(findIntersectionObserver().exists()).toBe(true);
    });

    it('emits an appear event when intersection-observer appears', () => {
      findIntersectionObserver().vm.$emit('appear');

      expect(wrapper.emitted('appear')).toEqual([[DEFAULT_PROPS.chunkIndex]]);
    });

    it('does not emit an appear event is isHighlighted is true', () => {
      createComponent({ isHighlighted: true });
      findIntersectionObserver().vm.$emit('appear');

      expect(wrapper.emitted('appear')).toEqual(undefined);
    });
  });

  describe('rendering', () => {
    it('does not render a Chunk Line component if isHighlighted is false', () => {
      expect(findChunkLines().length).toBe(0);
    });

    it('renders simplified line numbers and content if isHighlighted is false', () => {
      expect(findLineNumbers().length).toBe(DEFAULT_PROPS.totalLines);

      expect(findLineNumbers().at(0).attributes()).toMatchObject({
        'data-line-number': `${DEFAULT_PROPS.startingFrom + 1}`,
        href: `#L${DEFAULT_PROPS.startingFrom + 1}`,
        id: `L${DEFAULT_PROPS.startingFrom + 1}`,
      });

      expect(findContent().text()).toBe(DEFAULT_PROPS.content);
    });

    it('renders Chunk Line components if isHighlighted is true', () => {
      const splitContent = DEFAULT_PROPS.content.split('\n');
      createComponent({ isHighlighted: true });

      expect(findChunkLines().length).toBe(splitContent.length);

      expect(findChunkLines().at(0).props()).toMatchObject({
        number: DEFAULT_PROPS.startingFrom + 1,
        content: splitContent[0],
        language: DEFAULT_PROPS.language,
      });
    });
  });
});
