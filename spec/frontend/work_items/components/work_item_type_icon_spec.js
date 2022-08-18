import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';

let wrapper;

function createComponent(propsData) {
  wrapper = shallowMount(WorkItemTypeIcon, { propsData });
}

describe('Work Item type component', () => {
  const findIcon = () => wrapper.findComponent(GlIcon);

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    workItemType           | workItemIconName      | iconName                     | text
    ${'TASK'}              | ${''}                 | ${'issue-type-task'}         | ${'Task'}
    ${''}                  | ${'issue-type-task'}  | ${'issue-type-task'}         | ${''}
    ${'ISSUE'}             | ${''}                 | ${'issue-type-issue'}        | ${'Issue'}
    ${''}                  | ${'issue-type-issue'} | ${'issue-type-issue'}        | ${''}
    ${'REQUIREMENTS'}      | ${''}                 | ${'issue-type-requirements'} | ${'Requirements'}
    ${'INCIDENT'}          | ${''}                 | ${'issue-type-incident'}     | ${'Incident'}
    ${'TEST_CASE'}         | ${''}                 | ${'issue-type-test-case'}    | ${'Test case'}
    ${'random-issue-type'} | ${''}                 | ${'issue-type-issue'}        | ${''}
  `(
    'with workItemType set to "$workItemType" and workItemIconName set to "$workItemIconName"',
    ({ workItemType, workItemIconName, iconName, text }) => {
      beforeEach(() => {
        createComponent({
          workItemType,
          workItemIconName,
        });
      });

      it(`renders icon with name '${iconName}'`, () => {
        expect(findIcon().props('name')).toBe(iconName);
      });

      it(`renders correct text`, () => {
        expect(wrapper.text()).toBe(text);
      });
    },
  );
});
