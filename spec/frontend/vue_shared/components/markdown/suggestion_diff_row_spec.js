import { shallowMount, createLocalVue } from '@vue/test-utils';
import SuggestionDiffRow from '~/vue_shared/components/markdown/suggestion_diff_row.vue';

const oldLine = {
  can_receive_suggestion: false,
  line_code: null,
  meta_data: null,
  new_line: null,
  old_line: 5,
  rich_text: '-oldtext',
  text: '-oldtext',
  type: 'old',
};

const newLine = {
  can_receive_suggestion: false,
  line_code: null,
  meta_data: null,
  new_line: 6,
  old_line: null,
  rich_text: '-newtext',
  text: '-newtext',
  type: 'new',
};

describe('SuggestionDiffRow', () => {
  let wrapper;

  const factory = (options = {}) => {
    const localVue = createLocalVue();

    wrapper = shallowMount(SuggestionDiffRow, {
      localVue,
      ...options,
    });
  };

  const findOldLineWrapper = () => wrapper.find('.old_line');
  const findNewLineWrapper = () => wrapper.find('.new_line');

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders correctly', () => {
    factory({
      propsData: {
        line: oldLine,
      },
    });

    expect(wrapper.is('.line_holder')).toBe(true);
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
