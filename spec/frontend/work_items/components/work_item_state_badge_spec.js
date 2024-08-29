import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { STATE_OPEN, STATE_CLOSED } from '~/work_items/constants';
import WorkItemStateBadge from '~/work_items/components/work_item_state_badge.vue';

describe('WorkItemStateBadge', () => {
  let wrapper;

  const createComponent = ({ workItemState = STATE_OPEN, showIcon = true } = {}) => {
    wrapper = shallowMount(WorkItemStateBadge, {
      propsData: {
        workItemState,
        showIcon,
      },
    });
  };
  const findStatusBadge = () => wrapper.findComponent(GlBadge);

  it.each`
    state           | showIcon | icon              | stateText   | variant
    ${STATE_OPEN}   | ${true}  | ${'issue-open-m'} | ${'Open'}   | ${'success'}
    ${STATE_CLOSED} | ${true}  | ${'issue-close'}  | ${'Closed'} | ${'info'}
    ${STATE_OPEN}   | ${false} | ${null}           | ${'Open'}   | ${'success'}
    ${STATE_CLOSED} | ${false} | ${null}           | ${'Closed'} | ${'info'}
  `(
    'renders icon as "$icon" and text as "$stateText" when the work item state is "$state"',
    ({ state, showIcon, icon, stateText, variant }) => {
      createComponent({ workItemState: state, showIcon });

      expect(findStatusBadge().props('icon')).toBe(icon);
      expect(findStatusBadge().props('variant')).toBe(variant);
      expect(findStatusBadge().text()).toBe(stateText);
    },
  );
});
