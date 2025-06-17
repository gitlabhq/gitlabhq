import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

let wrapper;

function createComponent(propsData) {
  wrapper = shallowMountExtended(WorkItemTypeIcon, {
    propsData,
    directives: {
      GlTooltip: createMockDirective('gl-tooltip'),
    },
  });
}

describe('Work Item type component', () => {
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findButton = () => wrapper.findByTestId('work-item-type-icon');

  describe.each`
    workItemType           | iconName                     | text             | showTooltipOnHover | iconVariant
    ${'TASK'}              | ${'issue-type-task'}         | ${'Task'}        | ${false}           | ${'default'}
    ${'ISSUE'}             | ${'issue-type-issue'}        | ${'Issue'}       | ${true}            | ${'default'}
    ${'REQUIREMENT'}       | ${'issue-type-requirements'} | ${'Requirement'} | ${true}            | ${'default'}
    ${'INCIDENT'}          | ${'issue-type-incident'}     | ${'Incident'}    | ${false}           | ${'default'}
    ${'TEST_CASE'}         | ${'issue-type-test-case'}    | ${'Test case'}   | ${true}            | ${'default'}
    ${'random-issue-type'} | ${'issue-type-issue'}        | ${''}            | ${true}            | ${'default'}
    ${'Task'}              | ${'issue-type-task'}         | ${'Task'}        | ${false}           | ${'default'}
    ${'Issue'}             | ${'issue-type-issue'}        | ${'Issue'}       | ${true}            | ${'default'}
    ${'Requirement'}       | ${'issue-type-requirements'} | ${'Requirement'} | ${true}            | ${'default'}
    ${'Incident'}          | ${'issue-type-incident'}     | ${'Incident'}    | ${false}           | ${'default'}
    ${'Test_case'}         | ${'issue-type-test-case'}    | ${'Test case'}   | ${true}            | ${'default'}
    ${'Objective'}         | ${'issue-type-objective'}    | ${'Objective'}   | ${true}            | ${'default'}
    ${'Key Result'}        | ${'issue-type-keyresult'}    | ${'Key result'}  | ${true}            | ${'subtle'}
  `(
    'with workItemType set to "$workItemType"',
    ({ workItemType, iconName, text, showTooltipOnHover, iconVariant }) => {
      beforeEach(() => {
        createComponent({ workItemType, showTooltipOnHover, iconVariant });
      });

      it(`renders icon with name '${iconName}'`, () => {
        expect(findIcon().props('name')).toBe(iconName);
      });

      it(`renders correct text`, () => {
        expect(wrapper.text()).toBe(text);
      });

      it(`renders the icon in gray color based on '${iconVariant}'`, () => {
        expect(findIcon().props().variant).toEqual(iconVariant);
      });

      it('shows tooltip on hover when props passed', () => {
        const tooltip = getBinding(findButton().element, 'gl-tooltip');

        expect(tooltip.value).toBe(showTooltipOnHover);
      });
    },
  );
});
