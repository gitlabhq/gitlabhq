import { shallowMount } from '@vue/test-utils';
import { GlBadge, GlIcon } from '@gitlab/ui';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import ApprovalCount from '~/merge_requests/components/approval_count.vue';

let wrapper;

function createComponent(propsData = {}) {
  wrapper = shallowMount(ApprovalCount, {
    propsData,
    directives: {
      GlTooltip: createMockDirective('gl-tooltip'),
    },
  });
}

const findBadge = () => wrapper.findComponent(GlBadge);
const findIcon = () => wrapper.findComponent(GlIcon);
const findButton = () => wrapper.find('button');
const findTooltip = () => {
  const button = findButton();
  if (!button.exists()) {
    return null;
  }
  return getBinding(button.element, 'gl-tooltip');
};

describe('Merge request dashboard approval count FOSS component', () => {
  it('does not render badge when merge request is not approved', () => {
    createComponent({
      mergeRequest: { approvedBy: { nodes: [] } },
    });

    expect(findButton().exists()).toBe(false);
    expect(findBadge().exists()).toBe(false);
  });

  it('renders badge when merge request is approved', () => {
    createComponent({
      mergeRequest: { approvedBy: { nodes: ['approved'] } },
    });

    expect(findButton().exists()).toBe(true);
    expect(findBadge().exists()).toBe(true);
  });

  it.each`
    approvers | tooltipTitle
    ${[1]}    | ${'1 approval'}
    ${[1, 2]} | ${'2 approvals'}
  `('renders badge with correct tooltip title', ({ approvers, tooltipTitle }) => {
    createComponent({
      mergeRequest: { approvedBy: { nodes: approvers } },
    });

    expect(findButton().exists()).toBe(true);
    expect(findBadge().exists()).toBe(true);

    const tooltip = findTooltip();
    expect(tooltip).not.toBeNull();
    expect(tooltip.value).toBe(tooltipTitle);
  });

  describe('when neutral', () => {
    beforeEach(() => {
      createComponent({
        mergeRequest: { approvedBy: { nodes: ['approved', 'approved'] } },
        neutral: true,
      });
    });

    it('does not render the badge', () => {
      expect(findBadge().exists()).toBe(false);
    });

    it('renders a subtle approval icon and the count', () => {
      expect(findIcon().props('name')).toBe('approval');
      expect(findIcon().props('variant')).toBe('subtle');
      expect(findButton().text()).toBe('2');
    });
  });
});
