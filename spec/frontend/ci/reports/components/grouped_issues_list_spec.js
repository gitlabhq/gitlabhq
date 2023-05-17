import { shallowMount } from '@vue/test-utils';
import GroupedIssuesList from '~/ci/reports/components/grouped_issues_list.vue';
import ReportItem from '~/ci/reports/components/report_item.vue';
import SmartVirtualList from '~/vue_shared/components/smart_virtual_list.vue';

describe('Grouped Issues List', () => {
  let wrapper;

  const createComponent = ({ propsData = {}, stubs = {} } = {}) => {
    wrapper = shallowMount(GroupedIssuesList, {
      propsData,
      stubs,
    });
  };

  const findHeading = (groupName) => wrapper.find(`[data-testid="${groupName}Heading"`);

  it('renders a smart virtual list with the correct props', () => {
    createComponent({
      propsData: {
        resolvedIssues: [{ name: 'foo' }],
        unresolvedIssues: [{ name: 'bar' }],
      },
      stubs: {
        SmartVirtualList,
      },
    });

    expect(wrapper.findComponent(SmartVirtualList).props()).toMatchSnapshot();
  });

  describe('without data', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each(['unresolved', 'resolved'])('does not a render a header for %s issues', (issueName) => {
      expect(findHeading(issueName).exists()).toBe(false);
    });

    it.each(['resolved', 'unresolved'])('does not render report items for %s issues', () => {
      expect(wrapper.findComponent(ReportItem).exists()).toBe(false);
    });
  });

  describe('with data', () => {
    it.each`
      givenIssues                | givenHeading     | groupName
      ${[{ name: 'foo issue' }]} | ${'Foo Heading'} | ${'resolved'}
      ${[{ name: 'bar issue' }]} | ${'Bar Heading'} | ${'unresolved'}
    `('renders the heading for $groupName issues', ({ givenIssues, givenHeading, groupName }) => {
      createComponent({
        propsData: { [`${groupName}Issues`]: givenIssues, [`${groupName}Heading`]: givenHeading },
      });

      expect(findHeading(groupName).text()).toBe(givenHeading);
    });

    it.each(['resolved', 'unresolved'])('renders all %s issues', (issueName) => {
      const issues = [{ name: 'foo' }, { name: 'bar' }];

      createComponent({
        propsData: { [`${issueName}Issues`]: issues },
      });

      expect(wrapper.findAllComponents(ReportItem)).toHaveLength(issues.length);
    });

    it('renders a report item with the correct props', () => {
      createComponent({
        propsData: {
          resolvedIssues: [{ name: 'foo' }],
          component: 'CodequalityIssueBody',
        },
        stubs: {
          ReportItem,
        },
      });

      expect(wrapper.findComponent(ReportItem).props()).toMatchSnapshot();
    });
  });
});
