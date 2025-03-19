import { shallowMount } from '@vue/test-utils';
import IssueWeightCount from '~/boards/components/weight_count.vue';

describe('IssueWeightCount Component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(IssueWeightCount, {
      propsData: {
        ...props,
      },
    });
  };

  it('renders issue weight correctly', () => {
    createComponent({ issueWeight: 5 });
    expect(wrapper.text()).toContain('5');
  });

  it('renders max issue weight when set', () => {
    createComponent({ issueWeight: 5, maxIssueWeight: 10 });
    expect(wrapper.text()).toContain('/ 10');
  });

  it('does not render max issue weight when it is 0', () => {
    createComponent({ issueWeight: 5, maxIssueWeight: 0 });
    expect(wrapper.text()).not.toContain('/');
  });

  it('applies red text class when issue weight exceeds max issue weight', () => {
    createComponent({ issueWeight: 15, maxIssueWeight: 10 });
    expect(wrapper.find('[data-testid="board-weight-count"]').classes()).toContain(
      'gl-text-red-700',
    );
  });

  it('does not apply red text class when issue weight is within max limit', () => {
    createComponent({ issueWeight: 8, maxIssueWeight: 10 });
    expect(wrapper.find('[data-testid="board-weight-count"]').classes()).not.toContain(
      'gl-text-red-700',
    );
  });

  it('computes maxLimitText correctly', () => {
    createComponent({ maxIssueWeight: 10 });
    expect(wrapper.vm.maxLimitText).toBe('/ 10');
  });

  it('returns an empty string when maxIssueWeight is 0', () => {
    createComponent({ maxIssueWeight: 0 });
    expect(wrapper.vm.maxLimitText).toBe('');
  });

  it('computes issuesExceedMax correctly when exceeding max weight', () => {
    createComponent({ issueWeight: 12, maxIssueWeight: 10 });
    expect(wrapper.vm.issuesExceedMax).toBe(true);
  });

  it('computes issuesExceedMax correctly when within max weight', () => {
    createComponent({ issueWeight: 8, maxIssueWeight: 10 });
    expect(wrapper.vm.issuesExceedMax).toBe(false);
  });
});
