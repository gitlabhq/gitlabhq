import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

let wrapper;

function createComponent(propsData) {
  wrapper = shallowMount(WorkItemTypeIcon, {
    propsData,
    directives: {
      GlTooltip: createMockDirective('gl-tooltip'),
    },
  });
}

describe('Work Item type component', () => {
  const findIcon = () => wrapper.findComponent(GlIcon);

  describe.each`
    workItemType           | workItemIconName      | iconName                     | text              | showTooltipOnHover | colorClass
    ${'TASK'}              | ${''}                 | ${'issue-type-task'}         | ${'Task'}         | ${false}           | ${'gl-text-secondary'}
    ${''}                  | ${'issue-type-task'}  | ${'issue-type-task'}         | ${''}             | ${true}            | ${'gl-text-secondary'}
    ${'ISSUE'}             | ${''}                 | ${'issue-type-issue'}        | ${'Issue'}        | ${true}            | ${'gl-text-secondary'}
    ${''}                  | ${'issue-type-issue'} | ${'issue-type-issue'}        | ${''}             | ${true}            | ${'gl-text-secondary'}
    ${'REQUIREMENT'}       | ${''}                 | ${'issue-type-requirements'} | ${'Requirements'} | ${true}            | ${'gl-text-secondary'}
    ${'INCIDENT'}          | ${''}                 | ${'issue-type-incident'}     | ${'Incident'}     | ${false}           | ${'gl-text-secondary'}
    ${'TEST_CASE'}         | ${''}                 | ${'issue-type-test-case'}    | ${'Test case'}    | ${true}            | ${'gl-text-secondary'}
    ${'random-issue-type'} | ${''}                 | ${'issue-type-issue'}        | ${''}             | ${true}            | ${'gl-text-secondary'}
    ${'Task'}              | ${''}                 | ${'issue-type-task'}         | ${'Task'}         | ${false}           | ${'gl-text-secondary'}
    ${'Issue'}             | ${''}                 | ${'issue-type-issue'}        | ${'Issue'}        | ${true}            | ${'gl-text-secondary'}
    ${'Requirement'}       | ${''}                 | ${'issue-type-requirements'} | ${'Requirements'} | ${true}            | ${'gl-text-secondary'}
    ${'Incident'}          | ${''}                 | ${'issue-type-incident'}     | ${'Incident'}     | ${false}           | ${'gl-text-secondary'}
    ${'Test_case'}         | ${''}                 | ${'issue-type-test-case'}    | ${'Test case'}    | ${true}            | ${'gl-text-secondary'}
    ${'Objective'}         | ${''}                 | ${'issue-type-objective'}    | ${'Objective'}    | ${true}            | ${'gl-text-secondary'}
    ${'Key Result'}        | ${''}                 | ${'issue-type-keyresult'}    | ${'Key result'}   | ${true}            | ${'gl-text-gray-300'}
  `(
    'with workItemType set to "$workItemType" and workItemIconName set to "$workItemIconName"',
    ({ workItemType, workItemIconName, iconName, text, showTooltipOnHover, colorClass }) => {
      beforeEach(() => {
        createComponent({
          workItemType,
          workItemIconName,
          showTooltipOnHover,
          colorClass,
        });
      });

      it(`renders icon with name '${iconName}'`, () => {
        expect(findIcon().props('name')).toBe(iconName);
      });

      it(`renders correct text`, () => {
        expect(wrapper.text()).toBe(text);
      });

      it(`renders the icon in gray color based on '${colorClass}'`, () => {
        expect(findIcon().classes()).toContain(colorClass);
      });

      it('shows tooltip on hover when props passed', () => {
        const tooltip = getBinding(findIcon().element, 'gl-tooltip');

        expect(tooltip.value).toBe(showTooltipOnHover);
      });
    },
  );
});
