import { GlDisclosureDropdown, GlToggle, GlDisclosureDropdownItem } from '@gitlab/ui';
import { nextTick } from 'vue';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

import WorkItemMoreActions from '~/work_items/components/shared/work_item_more_actions.vue';

describe('WorkItemMoreActions', () => {
  /**
   * @type {import('@vue/test-utils').Wrapper}
   */
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findTooltip = () => getBinding(findDropdown().element, 'gl-tooltip');
  const findDropdownButton = () => findDropdown().find('button');
  const findViewRoadmapLink = () => wrapper.findByTestId('view-roadmap');
  const findToggle = (idx) => findDropdown().findAllComponents(GlToggle).at(idx);
  const findDropdownItems = () => findDropdown().findAllComponents(GlDisclosureDropdownItem);
  const findToggleDropdownItem = (idx) => findDropdownItems().at(idx);

  const createComponent = ({
    workItemType = 'Task',
    showViewRoadmapAction = true,
    showLabels = true,
  } = {}) => {
    wrapper = mountExtended(WorkItemMoreActions, {
      propsData: {
        workItemIid: '2',
        fullPath: 'project/group',
        workItemType,
        showLabels,
        showViewRoadmapAction,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('contains the correct tooltip text', () => {
    expect(findTooltip().value).toBe('More actions');
  });

  it('does not render the tooltip when the dropdown is shown', async () => {
    await findDropdownButton().trigger('click');

    await nextTick();

    expect(findTooltip().value).toBe('');
  });

  it('does not contain a roadmap page link when the work item type is not an Epic', () => {
    expect(findViewRoadmapLink().exists()).toBe(false);
  });

  it('contains a link to the roadmap page when the work item type is an Epic', () => {
    createComponent({ workItemType: 'Epic' });

    const link = findViewRoadmapLink();

    expect(link.text()).toBe('View on a roadmap');

    expect(link.attributes('href')).toBe(
      '/groups/project/group/-/roadmap?epic_iid=2&layout=MONTHS&timeframe_range_type=CURRENT_YEAR',
    );
  });

  it('renders the show labels toggle', () => {
    expect(findToggle(0).props('label')).toBe('Show labels');
  });

  it('renders the show closed toggle', () => {
    expect(findToggle(1).props('label')).toBe('Show closed items');
  });

  it('show labels toggle emits event when clicked on the dropdown item', () => {
    findToggleDropdownItem(0).vm.$emit('action');
    expect(wrapper.emitted('toggle-show-labels')).toStrictEqual([[]]);
  });

  describe('tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    beforeEach(() => {
      createComponent({ workItemType: 'Epic' });
    });

    it('View on roadmap button should have tracking', async () => {
      const { trackEventSpy } = bindInternalEventDocument(findDropdownItems().at(2).element);

      findDropdownItems().at(2).vm.$emit('action');
      await nextTick();

      expect(trackEventSpy).toHaveBeenCalledWith('view_epic_on_roadmap', {}, undefined);
    });
  });

  it('show closed toggle emits event when clicked on the dropdown item', () => {
    findToggleDropdownItem(1).vm.$emit('action');
    expect(wrapper.emitted('toggle-show-closed')).toStrictEqual([[]]);
  });
});
