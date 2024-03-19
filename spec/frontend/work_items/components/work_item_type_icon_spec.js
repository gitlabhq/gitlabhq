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
    workItemType           | workItemIconName      | iconName                     | text              | showTooltipOnHover
    ${'TASK'}              | ${''}                 | ${'issue-type-task'}         | ${'Task'}         | ${false}
    ${''}                  | ${'issue-type-task'}  | ${'issue-type-task'}         | ${''}             | ${true}
    ${'ISSUE'}             | ${''}                 | ${'issue-type-issue'}        | ${'Issue'}        | ${true}
    ${''}                  | ${'issue-type-issue'} | ${'issue-type-issue'}        | ${''}             | ${true}
    ${'REQUIREMENT'}       | ${''}                 | ${'issue-type-requirements'} | ${'Requirements'} | ${true}
    ${'INCIDENT'}          | ${''}                 | ${'issue-type-incident'}     | ${'Incident'}     | ${false}
    ${'TEST_CASE'}         | ${''}                 | ${'issue-type-test-case'}    | ${'Test case'}    | ${true}
    ${'random-issue-type'} | ${''}                 | ${'issue-type-issue'}        | ${''}             | ${true}
    ${'Task'}              | ${''}                 | ${'issue-type-task'}         | ${'Task'}         | ${false}
    ${'Issue'}             | ${''}                 | ${'issue-type-issue'}        | ${'Issue'}        | ${true}
    ${'Requirement'}       | ${''}                 | ${'issue-type-requirements'} | ${'Requirements'} | ${true}
    ${'Incident'}          | ${''}                 | ${'issue-type-incident'}     | ${'Incident'}     | ${false}
    ${'Test_case'}         | ${''}                 | ${'issue-type-test-case'}    | ${'Test case'}    | ${true}
    ${'Objective'}         | ${''}                 | ${'issue-type-objective'}    | ${'Objective'}    | ${true}
    ${'Key Result'}        | ${''}                 | ${'issue-type-keyresult'}    | ${'Key result'}   | ${true}
  `(
    'with workItemType set to "$workItemType" and workItemIconName set to "$workItemIconName"',
    ({ workItemType, workItemIconName, iconName, text, showTooltipOnHover }) => {
      beforeEach(() => {
        createComponent({
          workItemType,
          workItemIconName,
          showTooltipOnHover,
        });
      });

      it(`renders icon with name '${iconName}'`, () => {
        expect(findIcon().props('name')).toBe(iconName);
      });

      it(`renders correct text`, () => {
        expect(wrapper.text()).toBe(text);
      });

      it('renders the icon in gray color', () => {
        expect(findIcon().classes()).toContain('gl-text-secondary');
      });

      it('shows tooltip on hover when props passed', () => {
        const tooltip = getBinding(findIcon().element, 'gl-tooltip');

        expect(tooltip.value).toBe(showTooltipOnHover);
      });
    },
  );
});
