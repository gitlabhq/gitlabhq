import { shallowMount } from '@vue/test-utils';
import SuggestionDiffComponent from '~/vue_shared/components/markdown/suggestion_diff.vue';
import SuggestionDiffHeader from '~/vue_shared/components/markdown/suggestion_diff_header.vue';
import SuggestionDiffRow from '~/vue_shared/components/markdown/suggestion_diff_row.vue';

const suggestionId = 1;
const MOCK_DATA = {
  suggestion: {
    id: suggestionId,
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
    is_applying_batch: true,
  },
  helpPagePath: 'path_to_docs',
  defaultCommitMessage: 'Apply suggestion',
  batchSuggestionsInfo: [{ suggestionId }],
};

describe('Suggestion Diff component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(SuggestionDiffComponent, {
      propsData: {
        ...MOCK_DATA,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('matches snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders a correct amount of suggestion diff rows', () => {
    expect(wrapper.findAllComponents(SuggestionDiffRow)).toHaveLength(3);
  });

  it.each`
    event                | childArgs         | args
    ${'apply'}           | ${['test-event']} | ${[{ callback: 'test-event', suggestionId }]}
    ${'applyBatch'}      | ${['test-event']} | ${['test-event']}
    ${'addToBatch'}      | ${[]}             | ${[suggestionId]}
    ${'removeFromBatch'} | ${[]}             | ${[suggestionId]}
  `('emits $event event on sugestion diff header $event', ({ event, childArgs, args }) => {
    wrapper.findComponent(SuggestionDiffHeader).vm.$emit(event, ...childArgs);

    expect(wrapper.emitted(event)).toBeDefined();
    expect(wrapper.emitted(event)).toEqual([args]);
  });

  it('passes suggestion batch props to suggestion diff header', () => {
    expect(wrapper.findComponent(SuggestionDiffHeader).props()).toMatchObject({
      batchSuggestionsCount: 1,
      isBatched: true,
      isApplyingBatch: MOCK_DATA.suggestion.is_applying_batch,
    });
  });
});
