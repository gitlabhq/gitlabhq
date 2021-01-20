import Vue from 'vue';
import SuggestionsComponent from '~/vue_shared/components/markdown/suggestions.vue';

const MOCK_DATA = {
  suggestions: [
    {
      id: 1,
      appliable: true,
      applied: false,
      current_user: {
        can_apply: true,
      },
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
      ],
    },
  ],
  noteHtml: `
      <div class="suggestion">
      <div class="line">-oldtest</div>
    </div>
    <div class="suggestion">
      <div class="line">+newtest</div>
    </div>
  `,
  isApplied: false,
  helpPagePath: 'path_to_docs',
  defaultCommitMessage: 'Apply suggestion',
};

describe('Suggestion component', () => {
  let vm;
  let diffTable;

  beforeEach((done) => {
    const Component = Vue.extend(SuggestionsComponent);

    vm = new Component({
      propsData: MOCK_DATA,
    }).$mount();

    diffTable = vm.generateDiff(0).$mount().$el;

    jest.spyOn(vm, 'renderSuggestions').mockImplementation(() => {});
    vm.renderSuggestions();
    Vue.nextTick(done);
  });

  describe('mounted', () => {
    it('renders a flash container', () => {
      expect(vm.$el.querySelector('.js-suggestions-flash')).not.toBeNull();
    });

    it('renders a container for suggestions', () => {
      expect(vm.$refs.container).not.toBeNull();
    });

    it('renders suggestions', () => {
      expect(vm.renderSuggestions).toHaveBeenCalled();
      expect(vm.$el.innerHTML.includes('oldtest')).toBe(true);
      expect(vm.$el.innerHTML.includes('newtest')).toBe(true);
    });
  });

  describe('generateDiff', () => {
    it('generates a diff table', () => {
      expect(diffTable.querySelector('.md-suggestion-diff')).not.toBeNull();
    });

    it('generates a diff table that contains contents the suggested lines', () => {
      MOCK_DATA.suggestions[0].diff_lines.forEach((line) => {
        const text = line.text.substring(1);

        expect(diffTable.innerHTML.includes(text)).toBe(true);
      });
    });

    it('generates a diff table with the correct line number for each suggested line', () => {
      const lines = diffTable.querySelectorAll('.old_line');

      expect(parseInt([...lines][0].innerHTML, 10)).toBe(5);
    });
  });
});
