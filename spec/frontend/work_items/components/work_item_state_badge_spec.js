import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { STATE_OPEN, STATE_CLOSED } from '~/work_items/constants';
import WorkItemStateBadge from '~/work_items/components/work_item_state_badge.vue';

describe('WorkItemStateBadge', () => {
  let wrapper;

  const createComponent = ({ workItemState = STATE_OPEN } = {}) => {
    wrapper = shallowMount(WorkItemStateBadge, {
      propsData: {
        workItemState,
      },
    });
  };
  const findStatusBadge = () => wrapper.findComponent(GlBadge);

  it.each`
    state           | icon              | stateText   | variant
    ${STATE_OPEN}   | ${'issue-open-m'} | ${'Open'}   | ${'success'}
    ${STATE_CLOSED} | ${'issue-close'}  | ${'Closed'} | ${'info'}
  `(
    'renders icon as "$icon" and text as "$stateText" when the work item state is "$state"',
    ({ state, icon, stateText, variant }) => {
      createComponent({ workItemState: state });

      expect(findStatusBadge().props('icon')).toBe(icon);
      expect(findStatusBadge().props('variant')).toBe(variant);
      expect(findStatusBadge().text()).toBe(stateText);
    },
  );
});
