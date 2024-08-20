import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import IssuablePresenter from '~/glql/components/presenters/issuable.vue';
import StatePresenter from '~/glql/components/presenters/state.vue';
import TablePresenter from '~/glql/components/presenters/table.vue';
import TextPresenter from '~/glql/components/presenters/text.vue';
import UserPresenter from '~/glql/components/presenters/user.vue';
import Presenter from '~/glql/core/presenter';
import { MOCK_FIELDS, MOCK_ISSUES } from '../../mock_data';

describe('TablePresenter', () => {
  let wrapper;

  const createWrapper = ({ data, config, ...moreProps }, mountFn = shallowMountExtended) => {
    wrapper = mountFn(TablePresenter, {
      provide: {
        presenter: new Presenter().init({ data, config }),
      },
      propsData: { data, config, ...moreProps },
    });
  };

  it('renders header rows with sentence cased field names', () => {
    createWrapper({ data: MOCK_ISSUES, config: { fields: MOCK_FIELDS } });

    const headerRow = wrapper.find('thead tr');
    const headerCells = headerRow.findAll('th').wrappers.map((th) => th.text());

    expect(headerCells).toEqual(['Title', 'Author', 'State', 'Description']);
  });

  it('renders a row of items presented by appropriate presenters', () => {
    createWrapper({ data: MOCK_ISSUES, config: { fields: MOCK_FIELDS } }, mountExtended);

    const tableRow1 = wrapper.findByTestId('table-row-0');
    const tableRow2 = wrapper.findByTestId('table-row-1');

    const issuePresenter1 = tableRow1.findComponent(IssuablePresenter);
    const issuePresenter2 = tableRow2.findComponent(IssuablePresenter);
    const userPresenter1 = tableRow1.findComponent(UserPresenter);
    const userPresenter2 = tableRow2.findComponent(UserPresenter);
    const statePresenter1 = tableRow1.findComponent(StatePresenter);
    const statePresenter2 = tableRow2.findComponent(StatePresenter);
    const textPresenter1 = tableRow1.findComponent(TextPresenter);
    const textPresenter2 = tableRow2.findComponent(TextPresenter);

    expect(issuePresenter1.props('data')).toBe(MOCK_ISSUES.nodes[0]);
    expect(issuePresenter2.props('data')).toBe(MOCK_ISSUES.nodes[1]);
    expect(userPresenter1.props('data')).toBe(MOCK_ISSUES.nodes[0].author);
    expect(userPresenter2.props('data')).toBe(MOCK_ISSUES.nodes[1].author);
    expect(statePresenter1.props('data')).toBe(MOCK_ISSUES.nodes[0].state);
    expect(statePresenter2.props('data')).toBe(MOCK_ISSUES.nodes[1].state);
    expect(textPresenter1.props('data')).toBe(MOCK_ISSUES.nodes[0].description);
    expect(textPresenter2.props('data')).toBe(MOCK_ISSUES.nodes[1].description);

    const getCells = (row) => row.findAll('td').wrappers.map((td) => td.text());

    expect(getCells(tableRow1)).toEqual([
      'Issue 1 (#1)',
      '@foobar',
      'Open',
      'This is a description',
    ]);
    expect(getCells(tableRow2)).toEqual([
      'Issue 2 (#2 - closed)',
      '@janedoe',
      'Closed',
      'This is another description',
    ]);
  });

  it('shows a "No data" message if the list of items provided is empty', () => {
    createWrapper({ data: { nodes: [] }, config: { fields: MOCK_FIELDS } });

    expect(wrapper.text()).toContain('No data found for this query');
  });
});
