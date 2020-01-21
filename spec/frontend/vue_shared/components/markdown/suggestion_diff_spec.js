import Vue from 'vue';
import SuggestionDiffComponent from '~/vue_shared/components/markdown/suggestion_diff.vue';
import { selectDiffLines } from '~/vue_shared/components/lib/utils/diff_utils';

const MOCK_DATA = {
  canApply: true,
  suggestion: {
    id: 1,
    diff_lines: [
      {
        can_receive_suggestion: false,
        line_code: null,
        meta_data: null,
        new_line: null,
        old_line: 5,
        rich_text: '-test',
        text: '-test',
        type: 'old',
      },
      {
        can_receive_suggestion: true,
        line_code: null,
        meta_data: null,
        new_line: 5,
        old_line: null,
        rich_text: '+new test',
        text: '+new test',
        type: 'new',
      },
      {
        can_receive_suggestion: true,
        line_code: null,
        meta_data: null,
        new_line: 5,
        old_line: null,
        rich_text: '+new test2',
        text: '+new test2',
        type: 'new',
      },
    ],
  },
  helpPagePath: 'path_to_docs',
};

const lines = selectDiffLines(MOCK_DATA.suggestion.diff_lines);
const newLines = lines.filter(line => line.type === 'new');

describe('Suggestion Diff component', () => {
  let vm;

  beforeEach(done => {
    const Component = Vue.extend(SuggestionDiffComponent);

    vm = new Component({
      propsData: MOCK_DATA,
    }).$mount();

    Vue.nextTick(done);
  });

  describe('init', () => {
    it('renders a suggestion header', () => {
      expect(vm.$el.querySelector('.js-suggestion-diff-header')).not.toBeNull();
    });

    it('renders a diff table with syntax highlighting', () => {
      expect(vm.$el.querySelector('.md-suggestion-diff.js-syntax-highlight.code')).not.toBeNull();
    });

    it('renders the oldLineNumber', () => {
      const fromLine = vm.$el.querySelector('.old_line').innerHTML;

      expect(parseInt(fromLine, 10)).toBe(lines[0].old_line);
    });

    it('renders the oldLineContent', () => {
      const fromContent = vm.$el.querySelector('.line_content.old').innerHTML;

      expect(fromContent.includes(lines[0].text)).toBe(true);
    });

    it('renders new lines', () => {
      const newLinesElements = vm.$el.querySelectorAll('.line_holder.new');

      newLinesElements.forEach((line, i) => {
        expect(newLinesElements[i].innerHTML.includes(newLines[i].new_line)).toBe(true);
        expect(newLinesElements[i].innerHTML.includes(newLines[i].text)).toBe(true);
      });
    });
  });

  describe('applySuggestion', () => {
    it('emits apply event when applySuggestion is called', () => {
      const callback = () => {};
      jest.spyOn(vm, '$emit').mockImplementation(() => {});
      vm.applySuggestion(callback);

      expect(vm.$emit).toHaveBeenCalledWith('apply', { suggestionId: vm.suggestion.id, callback });
    });
  });
});
