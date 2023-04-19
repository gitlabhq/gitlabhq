import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
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
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mountExtended(SuggestionsComponent, {
      propsData: {
        ...MOCK_DATA,
        ...props,
      },
    });
  };

  const findSuggestionsContainer = () => wrapper.findByTestId('suggestions-container');

  beforeEach(async () => {
    createComponent();

    await nextTick();
  });

  describe('mounted', () => {
    it('renders a flash container', () => {
      expect(wrapper.find('.js-suggestions-flash').exists()).toBe(true);
    });

    it('renders a container for suggestions', () => {
      expect(findSuggestionsContainer().exists()).toBe(true);
    });

    it('renders suggestions', () => {
      expect(findSuggestionsContainer().text()).toContain('oldtest');
      expect(findSuggestionsContainer().text()).toContain('newtest');
    });
  });
});
