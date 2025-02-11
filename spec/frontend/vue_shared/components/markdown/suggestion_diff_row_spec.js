import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SuggestionDiffRow from '~/vue_shared/components/markdown/suggestion_diff_row.vue';

const oldLine = {
  can_receive_suggestion: false,
  line_code: null,
  meta_data: null,
  new_line: null,
  old_line: 5,
  rich_text: 'oldrichtext',
  text: 'oldplaintext',
  type: 'old',
};

const newLine = {
  can_receive_suggestion: false,
  line_code: null,
  meta_data: null,
  new_line: 6,
  old_line: null,
  rich_text: 'newrichtext',
  text: 'newplaintext',
  type: 'new',
};

describe('SuggestionDiffRow', () => {
  let wrapper;

  const factory = (options = {}) => {
    wrapper = shallowMountExtended(SuggestionDiffRow, {
      ...options,
    });
  };

  const findOldLineWrapper = () => wrapper.find('.old_line');
  const findNewLineWrapper = () => wrapper.find('.new_line');
  const findSuggestionContent = () => wrapper.findByTestId('suggestion-diff-content');

  describe('renders correctly', () => {
    it('renders the correct base suggestion markup', () => {
      factory({
        propsData: {
          line: oldLine,
        },
      });

      expect(findSuggestionContent().html()).toBe(
        '<td data-testid="suggestion-diff-content" class="line_content old"><span class="line">oldrichtext</span></td>',
      );
    });

    it('has the right classes on the wrapper', () => {
      factory({
        propsData: {
          line: oldLine,
        },
      });

      expect(wrapper.classes()).toContain('line_holder');
      expect(findSuggestionContent().find('span').classes()).toContain('line');
    });

    it('renders the rich text when it is available', () => {
      factory({
        propsData: {
          line: newLine,
        },
      });

      expect(wrapper.find('td.line_content').text()).toEqual('newrichtext');
    });

    it('renders the plain text when it is available but rich text is not', () => {
      factory({
        propsData: {
          line: {
            ...newLine,
            rich_text: undefined,
          },
        },
      });

      expect(wrapper.find('td.line_content').text()).toEqual('newplaintext');
    });

    it('switches to table-cell display when it has no plain or rich texts', () => {
      factory({
        propsData: {
          line: {
            ...newLine,
            text: undefined,
            rich_text: undefined,
          },
        },
      });

      const lineContent = wrapper.find('td.line_content');

      expect(lineContent.classes()).toContain('d-table-cell');
      expect(lineContent.text()).toEqual('');
    });

    it('does not switch to table-cell display if it has either plain or rich texts', () => {
      let lineContent;

      factory({
        propsData: {
          line: {
            ...newLine,
            text: undefined,
          },
        },
      });

      lineContent = wrapper.find('td.line_content');
      expect(lineContent.classes()).not.toContain('d-table-cell');

      factory({
        propsData: {
          line: {
            ...newLine,
            rich_text: undefined,
          },
        },
      });

      lineContent = wrapper.find('td.line_content');
      expect(lineContent.classes()).not.toContain('d-table-cell');
    });
  });

  describe('when passed line has type old', () => {
    beforeEach(() => {
      factory({
        propsData: {
          line: oldLine,
        },
      });
    });

    it('has old class when line has type old', () => {
      expect(wrapper.find('td').classes()).toContain('old');
    });

    it('has old line number rendered', () => {
      expect(findOldLineWrapper().text()).toBe('5');
    });

    it('has no new line number rendered', () => {
      expect(findNewLineWrapper().text()).toBe('');
    });
  });

  describe('when passed line has type new', () => {
    beforeEach(() => {
      factory({
        propsData: {
          line: newLine,
        },
      });
    });

    it('has new class when line has type new', () => {
      expect(wrapper.find('td').classes()).toContain('new');
    });

    it('has no old line number rendered', () => {
      expect(findOldLineWrapper().text()).toBe('');
    });

    it('has no new line number rendered', () => {
      expect(findNewLineWrapper().text()).toBe('6');
    });
  });
});
