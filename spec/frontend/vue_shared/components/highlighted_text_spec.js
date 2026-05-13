import { mountExtended } from 'helpers/vue_test_utils_helper';
import HighlightedText from '~/vue_shared/components/highlighted_text.vue';

describe('HighlightedText', () => {
  let wrapper;

  const createWrapper = (props) => {
    wrapper = mountExtended(HighlightedText, { propsData: props });
  };

  const findHighlightedSegments = () => wrapper.findAllByTestId('highlighted-segment');
  const findUnhighlightedSegments = () => wrapper.findAllByTestId('unhighlighted-segment');

  it('renders plain text with no highlighted segments when no match is provided', () => {
    createWrapper({ text: 'gitlab' });
    expect(wrapper.text()).toBe('gitlab');
    expect(findHighlightedSegments()).toHaveLength(0);
    expect(findUnhighlightedSegments()).toHaveLength(1);
  });

  it('renders empty when text is empty', () => {
    createWrapper({ text: '' });
    expect(wrapper.text()).toBe('');
    expect(findHighlightedSegments()).toHaveLength(0);
    expect(findUnhighlightedSegments()).toHaveLength(0);
  });

  it('renders highlighted and unhighlighted segments for a fuzzy match', () => {
    createWrapper({ text: 'gitlab', match: 'it' });
    expect(wrapper.text()).toBe('gitlab');
    expect(findHighlightedSegments()).toHaveLength(1);
    expect(findHighlightedSegments().at(0).text()).toBe('it');
    expect(findHighlightedSegments().at(0).classes()).toContain('gl-font-bold');
  });

  it('highlights all occurrences when global is true', () => {
    createWrapper({ text: 'lib/utils/lib_helper.js', match: 'lib', global: true });
    expect(findHighlightedSegments().wrappers.map((s) => s.text())).toEqual(['lib', 'lib']);
  });

  describe('with highlightClass', () => {
    it('uses the given class instead of gl-font-bold', () => {
      createWrapper({ text: 'gitlab', match: 'it', highlightClass: 'highlight-search-term' });
      expect(wrapper.find('span.gl-font-bold').exists()).toBe(false);
      expect(wrapper.find('span.highlight-search-term').exists()).toBe(true);
    });
  });
});
