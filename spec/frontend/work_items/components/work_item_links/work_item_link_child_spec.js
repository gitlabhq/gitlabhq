import { GlButton, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import RichTimestampTooltip from '~/vue_shared/components/rich_timestamp_tooltip.vue';

import WorkItemLinkChild from '~/work_items/components/work_item_links/work_item_link_child.vue';
import WorkItemLinksMenu from '~/work_items/components/work_item_links/work_item_links_menu.vue';

import { workItemTask, confidentialWorkItemTask, closedWorkItemTask } from '../../mock_data';

describe('WorkItemLinkChild', () => {
  const WORK_ITEM_ID = 'gid://gitlab/WorkItem/2';
  let wrapper;

  const createComponent = ({
    projectPath = 'gitlab-org/gitlab-test',
    canUpdate = true,
    issuableGid = WORK_ITEM_ID,
    childItem = workItemTask,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemLinkChild, {
      propsData: {
        projectPath,
        canUpdate,
        issuableGid,
        childItem,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    status      | childItem             | statusIconName    | statusIconColorClass   | rawTimestamp                   | tooltipContents
    ${'open'}   | ${workItemTask}       | ${'issue-open-m'} | ${'gl-text-green-500'} | ${workItemTask.createdAt}      | ${'Created'}
    ${'closed'} | ${closedWorkItemTask} | ${'issue-close'}  | ${'gl-text-blue-500'}  | ${closedWorkItemTask.closedAt} | ${'Closed'}
  `(
    'renders item status icon and tooltip when item status is `$status`',
    ({ childItem, statusIconName, statusIconColorClass, rawTimestamp, tooltipContents }) => {
      createComponent({ childItem });

      const statusIcon = wrapper.findByTestId('item-status-icon').findComponent(GlIcon);
      const statusTooltip = wrapper.findComponent(RichTimestampTooltip);

      expect(statusIcon.props('name')).toBe(statusIconName);
      expect(statusIcon.classes()).toContain(statusIconColorClass);
      expect(statusTooltip.props('rawTimestamp')).toBe(rawTimestamp);
      expect(statusTooltip.props('timestampTypeText')).toContain(tooltipContents);
    },
  );

  it('renders confidential icon when item is confidential', () => {
    createComponent({ childItem: confidentialWorkItemTask });

    const confidentialIcon = wrapper.findByTestId('confidential-icon');

    expect(confidentialIcon.props('name')).toBe('eye-slash');
    expect(confidentialIcon.attributes('title')).toBe('Confidential');
  });

  describe('item title', () => {
    let titleEl;

    beforeEach(() => {
      createComponent();

      titleEl = wrapper.findComponent(GlButton);
    });

    it('renders item title', () => {
      expect(titleEl.attributes('href')).toBe('/gitlab-org/gitlab-test/-/work_items/4');
      expect(titleEl.text()).toBe(workItemTask.title);
    });

    it.each`
      action                  | event          | emittedEvent
      ${'doing mouseover on'} | ${'mouseover'} | ${'mouseover'}
      ${'doing mouseout on'}  | ${'mouseout'}  | ${'mouseout'}
    `('$action item title emit `$emittedEvent` event', ({ event, emittedEvent }) => {
      titleEl.vm.$emit(event);

      expect(wrapper.emitted(emittedEvent)).toEqual([[]]);
    });

    it('emits click event with correct parameters on clicking title', () => {
      const eventObj = {
        preventDefault: jest.fn(),
      };
      titleEl.vm.$emit('click', eventObj);

      expect(wrapper.emitted('click')).toEqual([[eventObj]]);
    });
  });

  describe('item menu', () => {
    let itemMenuEl;

    beforeEach(() => {
      createComponent();

      itemMenuEl = wrapper.findComponent(WorkItemLinksMenu);
    });

    it('renders work-item-links-menu', () => {
      expect(itemMenuEl.exists()).toBe(true);

      expect(itemMenuEl.attributes()).toMatchObject({
        'work-item-id': workItemTask.id,
        'parent-work-item-id': WORK_ITEM_ID,
      });
    });

    it('does not render work-item-links-menu when canUpdate is false', () => {
      createComponent({ canUpdate: false });

      expect(wrapper.findComponent(WorkItemLinksMenu).exists()).toBe(false);
    });

    it('removeChild event on menu triggers `click-remove-child` event', () => {
      itemMenuEl.vm.$emit('removeChild');

      expect(wrapper.emitted('remove')).toEqual([[workItemTask.id]]);
    });
  });
});
