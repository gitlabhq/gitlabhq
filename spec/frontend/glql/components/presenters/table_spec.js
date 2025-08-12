import { nextTick } from 'vue';
import { GlSkeletonLoader } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ThResizable from '~/glql/components/common/th_resizable.vue';
import IssuablePresenter from '~/glql/components/presenters/issuable.vue';
import StatePresenter from '~/glql/components/presenters/state.vue';
import TablePresenter from '~/glql/components/presenters/table.vue';
import HtmlPresenter from '~/glql/components/presenters/html.vue';
import UserPresenter from '~/glql/components/presenters/user.vue';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { MOCK_FIELDS, MOCK_ISSUES } from '../../mock_data';

describe('TablePresenter', () => {
  let wrapper;

  useMockLocationHelper();

  beforeEach(() => {
    window.location.href = 'https://gitlab.com/gitlab-org/gitlab-shell/-/issues/1';
    window.location.origin = 'https://gitlab.com';
  });

  const createWrapper = async ({ data, fields, ...moreProps }, mountFn = shallowMountExtended) => {
    wrapper = mountFn(TablePresenter, {
      propsData: { data, fields, ...moreProps },
    });

    await nextTick();
  };

  const getCells = (row) => row.findAll('td').wrappers.map((td) => td.text());

  it('renders header rows with sentence cased field names', async () => {
    await createWrapper({ data: MOCK_ISSUES, fields: MOCK_FIELDS });

    const headerCells = wrapper.findAllComponents(ThResizable).wrappers.map((th) => th.text());

    expect(headerCells).toEqual(['Title', 'Author', 'State', 'Description']);
  });

  it('renders skeleton loader if loading is true', () => {
    createWrapper({ data: { nodes: [] }, fields: MOCK_FIELDS, loading: true }, mountExtended);

    // 5 rows of 4 columns each
    expect(wrapper.findAllComponents(GlSkeletonLoader)).toHaveLength(20);
  });

  it('renders a row of items presented by appropriate presenters', async () => {
    await createWrapper({ data: MOCK_ISSUES, fields: MOCK_FIELDS }, mountExtended);

    const tableRow1 = wrapper.findByTestId('table-row-0');
    const tableRow2 = wrapper.findByTestId('table-row-1');

    const issuePresenter1 = tableRow1.findComponent(IssuablePresenter);
    const issuePresenter2 = tableRow2.findComponent(IssuablePresenter);
    const userPresenter1 = tableRow1.findComponent(UserPresenter);
    const userPresenter2 = tableRow2.findComponent(UserPresenter);
    const statePresenter1 = tableRow1.findComponent(StatePresenter);
    const statePresenter2 = tableRow2.findComponent(StatePresenter);
    const htmlPresenter1 = tableRow1.findComponent(HtmlPresenter);
    const htmlPresenter2 = tableRow2.findComponent(HtmlPresenter);

    expect(issuePresenter1.props('data')).toBe(MOCK_ISSUES.nodes[0]);
    expect(issuePresenter2.props('data')).toBe(MOCK_ISSUES.nodes[1]);
    expect(userPresenter1.props('data')).toBe(MOCK_ISSUES.nodes[0].author);
    expect(userPresenter2.props('data')).toBe(MOCK_ISSUES.nodes[1].author);
    expect(statePresenter1.props('data')).toBe(MOCK_ISSUES.nodes[0].state);
    expect(statePresenter2.props('data')).toBe(MOCK_ISSUES.nodes[1].state);
    expect(htmlPresenter1.props('data')).toBe(MOCK_ISSUES.nodes[0].description);
    expect(htmlPresenter2.props('data')).toBe(MOCK_ISSUES.nodes[1].description);

    expect(getCells(tableRow1)).toEqual([
      'Issue 1 (gitlab-test#1)',
      '@foobar',
      'Open',
      'This is a description',
    ]);
    expect(getCells(tableRow2)).toEqual([
      'Issue 2 (gitlab-test#2 - closed)',
      '@janedoe',
      'Closed',
      'This is another description',
    ]);
  });

  const order0 = [
    ['Issue 1 (gitlab-test#1)', '@foobar', 'Open', 'This is a description'],
    ['Issue 2 (gitlab-test#2 - closed)', '@janedoe', 'Closed', 'This is another description'],
  ];

  const order1 = [
    ['Issue 2 (gitlab-test#2 - closed)', '@janedoe', 'Closed', 'This is another description'],
    ['Issue 1 (gitlab-test#1)', '@foobar', 'Open', 'This is a description'],
  ];

  describe.each`
    cellIndex | headerTitle      | orderAsc  | orderDesc
    ${0}      | ${'title'}       | ${order0} | ${order1}
    ${1}      | ${'author'}      | ${order0} | ${order1}
    ${2}      | ${'state'}       | ${order0} | ${order1}
    ${3}      | ${'description'} | ${order0} | ${order1}
  `('when clicking on header cell at index $cellIndex', ({ cellIndex, orderAsc, orderDesc }) => {
    let actualOrder;

    const triggerClick = async () => {
      await nextTick();
      await wrapper.findByTestId(`column-${cellIndex}`).trigger('click');

      actualOrder = wrapper.findAll('tbody tr').wrappers.map(getCells);
    };

    beforeEach(async () => {
      await createWrapper({ data: MOCK_ISSUES, fields: MOCK_FIELDS }, mountExtended);

      await triggerClick();
    });

    describe('once', () => {
      it('sorts the table by the field in ascending order', () => {
        expect(actualOrder).toEqual(orderAsc);
      });
    });

    describe('twice', () => {
      beforeEach(async () => {
        await triggerClick();
      });

      it('sorts the table by the field in descending order', () => {
        expect(actualOrder).toEqual(orderDesc);
      });
    });
  });
});
