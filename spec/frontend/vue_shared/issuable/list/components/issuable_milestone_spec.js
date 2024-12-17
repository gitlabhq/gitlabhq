import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { useFakeDate } from 'helpers/fake_date';
import IssuableMilestone from '~/vue_shared/issuable/list/components/issuable_milestone.vue';
import WorkItemAttribute from '~/vue_shared/components/work_item_attribute.vue';

describe('IssuableMilestone component', () => {
  useFakeDate(2020, 11, 11); // 2020 Dec 11

  let wrapper;

  const milestoneObject = ({ milestoneStartDate, milestoneDueDate } = {}) => ({
    dueDate: milestoneDueDate,
    startDate: milestoneStartDate,
    title: 'My milestone',
    webPath: '/milestone/webPath',
  });

  const findWorkItemAttribute = () => wrapper.findComponent(WorkItemAttribute);

  const mountComponent = ({ milestone = milestoneObject() } = {}) =>
    shallowMount(IssuableMilestone, { propsData: { milestone }, stubs: { WorkItemAttribute } });

  it('renders milestone link', () => {
    wrapper = mountComponent();
    const milestoneEl = wrapper.find('[data-testid="issuable-milestone"]');

    expect(findWorkItemAttribute().props('title')).toBe('My milestone');
    expect(milestoneEl.findComponent(GlIcon).props('name')).toBe('milestone');
    expect(findWorkItemAttribute().props('href')).toBe('/milestone/webPath');
  });

  describe.each`
    time                         | text                   | milestoneDueDate | milestoneStartDate | expected
    ${'due date is in past'}     | ${'past due'}          | ${'2020-09-09'}  | ${null}            | ${'Sep 9, 2020 (past due)'}
    ${'due date is today'}       | ${'today'}             | ${'2020-12-11'}  | ${null}            | ${'Dec 11, 2020 (today)'}
    ${'start date is in future'} | ${'upcoming'}          | ${'2021-03-01'}  | ${'2021-02-01'}    | ${'Mar 1, 2021 (upcoming)'}
    ${'due date is in future'}   | ${'2 weeks remaining'} | ${'2020-12-25'}  | ${null}            | ${'Dec 25, 2020 (2 weeks remaining)'}
  `('when $description', ({ text, milestoneDueDate, milestoneStartDate, expected }) => {
    it(`renders with "${text}"`, () => {
      wrapper = mountComponent({
        milestone: milestoneObject({ milestoneDueDate, milestoneStartDate }),
      });

      expect(findWorkItemAttribute().props('tooltipText')).toBe(expected);
    });
  });
});
