import { shallowMount } from '@vue/test-utils';
import SuggestionDiffComponent from '~/vue_shared/components/markdown/suggestion_diff.vue';
import SuggestionDiffHeader from '~/vue_shared/components/markdown/suggestion_diff_header.vue';
import SuggestionDiffRow from '~/vue_shared/components/markdown/suggestion_diff_row.vue';

const MOCK_DATA = {
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

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('matches snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders a correct amount of suggestion diff rows', () => {
    expect(wrapper.findAll(SuggestionDiffRow)).toHaveLength(3);
  });

  it('emits apply event on sugestion diff header apply', () => {
    wrapper.find(SuggestionDiffHeader).vm.$emit('apply', 'test-event');

    expect(wrapper.emitted('apply')).toBeDefined();
    expect(wrapper.emitted('apply')).toEqual([
      [
        {
          callback: 'test-event',
          suggestionId: 1,
        },
      ],
    ]);
  });
});
