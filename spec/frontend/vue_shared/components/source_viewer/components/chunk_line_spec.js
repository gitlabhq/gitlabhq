import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ChunkLine from '~/vue_shared/components/source_viewer/components/chunk_line.vue';

const DEFAULT_PROPS = {
  number: 2,
  content: '// Line content',
  language: 'javascript',
};

describe('Chunk Line component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ChunkLine, { propsData: { ...DEFAULT_PROPS, ...props } });
  };

  const findLink = () => wrapper.findComponent(GlLink);
  const findContent = () => wrapper.findByTestId('content');

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => wrapper.destroy());

  describe('rendering', () => {
    it('renders a line number', () => {
      expect(findLink().attributes()).toMatchObject({
        'data-line-number': `${DEFAULT_PROPS.number}`,
        to: `#L${DEFAULT_PROPS.number}`,
        id: `L${DEFAULT_PROPS.number}`,
      });

      expect(findLink().text()).toBe(DEFAULT_PROPS.number.toString());
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
