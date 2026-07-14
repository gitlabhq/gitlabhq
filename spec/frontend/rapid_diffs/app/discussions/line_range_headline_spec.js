import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import LineRangeHeadline from '~/rapid_diffs/app/discussions/line_range_headline.vue';

describe('LineRangeHeadline', () => {
  let wrapper;

  const lineRange = (start, end) => ({
    start: { old_line: null, new_line: start, type: 'new' },
    end: { old_line: null, new_line: end, type: 'new' },
  });

  const createComponent = (props = {}, slots = {}) => {
    wrapper = shallowMount(LineRangeHeadline, {
      propsData: props,
      slots,
      stubs: { GlSprintf },
    });
  };

  const findSprintf = () => wrapper.findComponent(GlSprintf);

  it('does not render without a line range', () => {
    createComponent();
    expect(findSprintf().exists()).toBe(false);
  });

  it('renders the single line for a single-line range', () => {
    createComponent({ lineRange: lineRange(5, 5) });
    expect(wrapper.text()).toContain('Comment on line +5');
  });

  it('renders the line range for a multi-line range', () => {
    createComponent({ lineRange: lineRange(5, 8) });
    expect(wrapper.text()).toContain('Comment on lines +5 to +8');
  });

  it('renders default slot content alongside the line range', () => {
    createComponent({ lineRange: lineRange(5, 8) }, { default: '<button>Edit</button>' });
    expect(wrapper.find('button').exists()).toBe(true);
  });
});
