import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ChunkLine from '~/vue_shared/components/source_viewer/components/chunk_line.vue';
import {
  BIDI_CHARS,
  BIDI_CHARS_CLASS_LIST,
  BIDI_CHAR_TOOLTIP,
} from '~/vue_shared/components/source_viewer/constants';

const DEFAULT_PROPS = {
  number: 2,
  content: '// Line content',
  language: 'javascript',
  blamePath: 'blame/file.js',
};

describe('Chunk Line component', () => {
  let wrapper;
  const fileLineBlame = true;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ChunkLine, {
      propsData: { ...DEFAULT_PROPS, ...props },
      provide: {
        glFeatures: {
          fileLineBlame,
        },
      },
    });
  };

  const findLineLink = () => wrapper.find('.file-line-num');
  const findBlameLink = () => wrapper.find('.file-line-blame');
  const findContent = () => wrapper.findByTestId('content');
  const findWrappedBidiChars = () => wrapper.findAllByTestId('bidi-wrapper');

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => wrapper.destroy());

  describe('rendering', () => {
    it('wraps BiDi characters', () => {
      const content = `// some content ${BIDI_CHARS.toString()} with BiDi chars`;
      createComponent({ content });
      const wrappedBidiChars = findWrappedBidiChars();

      expect(wrappedBidiChars.length).toBe(BIDI_CHARS.length);

      wrappedBidiChars.wrappers.forEach((_, i) => {
        expect(wrappedBidiChars.at(i).text()).toBe(BIDI_CHARS[i]);
        expect(wrappedBidiChars.at(i).attributes()).toMatchObject({
          class: BIDI_CHARS_CLASS_LIST,
          title: BIDI_CHAR_TOOLTIP,
        });
      });
    });

    it('renders a blame link', () => {
      expect(findBlameLink().attributes()).toMatchObject({
        href: `${DEFAULT_PROPS.blamePath}#L${DEFAULT_PROPS.number}`,
      });

      expect(findBlameLink().text()).toBe('');
    });

    it('renders a line number', () => {
      expect(findLineLink().attributes()).toMatchObject({
        'data-line-number': `${DEFAULT_PROPS.number}`,
        href: `#L${DEFAULT_PROPS.number}`,
        id: `L${DEFAULT_PROPS.number}`,
      });

      expect(findLineLink().text()).toBe(DEFAULT_PROPS.number.toString());
    });

    it('renders content', () => {
      expect(findContent().attributes()).toMatchObject({
        id: `LC${DEFAULT_PROPS.number}`,
        lang: DEFAULT_PROPS.language,
      });

      expect(findContent().text()).toBe(DEFAULT_PROPS.content);
    });
  });
});
