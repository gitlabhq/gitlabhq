import { GlBadge, GlLink, GlSprintf } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { STATE_OPEN, STATE_CLOSED } from '~/work_items/constants';
import WorkItemStateBadge from '~/work_items/components/work_item_state_badge.vue';

describe('WorkItemStateBadge', () => {
  let wrapper;

  const createComponent = ({
    workItemState = STATE_OPEN,
    showIcon = true,
    movedToWorkItemUrl = '',
    duplicatedToWorkItemUrl = '',
    promotedToEpicUrl = '',
  } = {}) => {
    wrapper = mount(WorkItemStateBadge, {
      propsData: {
        workItemState,
        showIcon,
        movedToWorkItemUrl,
        duplicatedToWorkItemUrl,
        promotedToEpicUrl,
      },
    });
  };

  const findStatusBadge = () => wrapper.findComponent(GlBadge);
  const findGlSprintf = () => wrapper.findComponent(GlSprintf);
  const findGlLink = () => wrapper.findComponent(GlLink);

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

  describe('closed state with link', () => {
    it.each`
      attribute                    | url                                | expectedText
      ${'movedToWorkItemUrl'}      | ${'http://example.com/moved'}      | ${'Closed (moved)'}
      ${'duplicatedToWorkItemUrl'} | ${'http://example.com/duplicated'} | ${'Closed (duplicated)'}
      ${'promotedToEpicUrl'}       | ${'http://example.com/epic'}       | ${'Closed (promoted)'}
    `(
      'renders correct text and link when $attribute is present on work item',
      ({ attribute, url, expectedText }) => {
        const props = {
          workItemState: STATE_CLOSED,
          [attribute]: url,
        };
        createComponent(props);

        expect(findGlSprintf().exists()).toBe(true);
        expect(wrapper.text()).toContain(expectedText);
        expect(findGlLink().attributes('href')).toBe(url);
      },
    );
  });
});
