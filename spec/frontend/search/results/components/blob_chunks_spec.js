import { GlIcon, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BlobChunks from '~/search/results/components/blob_chunks.vue';

describe('BlobChunks', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMountExtended(BlobChunks, {
      propsData: {
        ...props,
      },
      stubs: {
        GlLink,
      },
    });
  };

  const findGlIcon = () => wrapper.findAllComponents(GlIcon);
  const findGlLink = () => wrapper.findAllComponents(GlLink);
  const findLine = () => wrapper.findAllByTestId('search-blob-line');
  const findLineNumbers = () => wrapper.findAllByTestId('search-blob-line-numbers');
  const findLineCode = () => wrapper.findAllByTestId('search-blob-line-code');
  const findRootElement = () => wrapper.find('#search-blob-content');

  describe('component basics', () => {
    beforeEach(() => {
      createComponent({
        chunk: {
          lines: [
            {
              lineNumber: 1,
              richText: '',
              text: '',
              __typename: 'SearchBlobLine',
            },
            {
              lineNumber: 2,
              richText: '<b>test1</b>',
              text: 'test1',
              __typename: 'SearchBlobLine',
            },
            { lineNumber: 3, richText: '', text: '', __typename: 'SearchBlobLine' },
          ],
          matchCountInChunk: 1,
          __typename: 'SearchBlobChunk',
        },
        blameLink: 'https://gitlab.com/blame/test.js',
        fileUrl: 'https://gitlab.com/file/test.js',
      });
    });

    it(`renders default state`, () => {
      expect(findLine()).toHaveLength(3);
      expect(findLineNumbers()).toHaveLength(3);
      expect(findLineCode()).toHaveLength(3);
      expect(findGlLink()).toHaveLength(6);
      expect(findGlIcon()).toHaveLength(3);
    });

    it(`renders proper colors`, () => {
      expect(findRootElement().classes('white')).toBe(true);
      expect(findLineCode().at(1).find('b').classes('hll')).toBe(true);
    });

    it(`renders links correctly`, () => {
      expect(findGlLink().at(0).attributes('href')).toBe('https://gitlab.com/blame/test.js#L1');
      expect(findGlLink().at(0).attributes('title')).toBe('View blame');
      expect(findGlLink().at(0).findComponent(GlIcon).exists()).toBe(true);
      expect(findGlLink().at(0).findComponent(GlIcon).props('name')).toBe('git');

      expect(findGlLink().at(1).attributes('href')).toBe('https://gitlab.com/file/test.js#L1');
      expect(findGlLink().at(1).attributes('title')).toBe('View Line in repository');
      expect(findGlLink().at(1).text()).toBe('1');
    });
  });
});
