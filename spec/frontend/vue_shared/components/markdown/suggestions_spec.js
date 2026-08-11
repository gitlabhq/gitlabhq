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

  describe('when a rendered suggestion diff emits a batch event', () => {
    const noteHtmlWithSuggestion = `
      <div class="suggestion">
        <div class="js-render-suggestion">+newtest</div>
      </div>
    `;

    const createWithRenderedSuggestion = async (props = {}) => {
      createComponent({ noteHtml: noteHtmlWithSuggestion, suggestionsCount: 2, ...props });
      await nextTick();
    };

    beforeEach(() => {
      window.gon = { current_user_id: 1 };
    });

    it('emits `add-to-batch` when the add to batch button is clicked', async () => {
      await createWithRenderedSuggestion();

      await wrapper.find('.js-add-to-batch-btn').trigger('click');

      expect(wrapper.emitted('add-to-batch')).toEqual([[MOCK_DATA.suggestions[0].id]]);
    });

    it('emits `remove-from-batch` when the remove from batch button is clicked', async () => {
      await createWithRenderedSuggestion({
        batchSuggestionsInfo: [{ suggestionId: MOCK_DATA.suggestions[0].id }],
      });

      await wrapper.find('.js-remove-from-batch-btn').trigger('click');

      expect(wrapper.emitted('remove-from-batch')).toEqual([[MOCK_DATA.suggestions[0].id]]);
    });

    it('emits `apply-batch` when the apply suggestions button is clicked', async () => {
      await createWithRenderedSuggestion({
        batchSuggestionsInfo: [{ suggestionId: MOCK_DATA.suggestions[0].id }, { suggestionId: 2 }],
      });

      await wrapper.find('[data-testid="commit-with-custom-message-button"]').trigger('click');

      expect(wrapper.emitted('apply-batch')).toEqual([
        [{ message: null, flashContainer: wrapper.vm.$el }],
      ]);
    });
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
