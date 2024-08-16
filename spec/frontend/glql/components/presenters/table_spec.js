import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import TablePresenter from '~/glql/components/presenters/table.vue';
import TextPresenter from '~/glql/components/presenters/text.vue';
import LinkPresenter from '~/glql/components/presenters/link.vue';
import Presenter from '~/glql/core/presenter';
import { MOCK_ISSUES, MOCK_FIELDS } from '../../mock_data';

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

    const linkPresenters1 = tableRow1.findAllComponents(LinkPresenter);
    const linkPresenters2 = tableRow2.findAllComponents(LinkPresenter);
    const textPresenter1 = tableRow1.findComponent(TextPresenter);
    const textPresenter2 = tableRow2.findComponent(TextPresenter);

    expect(linkPresenters1).toHaveLength(2);
    expect(linkPresenters2).toHaveLength(2);

    expect(linkPresenters1.at(0).props('data')).toBe(MOCK_ISSUES.nodes[0]);
    expect(linkPresenters1.at(1).props('data')).toBe(MOCK_ISSUES.nodes[0].author);
    expect(linkPresenters2.at(0).props('data')).toBe(MOCK_ISSUES.nodes[1]);
    expect(linkPresenters2.at(1).props('data')).toBe(MOCK_ISSUES.nodes[1].author);

    expect(textPresenter1.props('data')).toBe(MOCK_ISSUES.nodes[0].description);
    expect(textPresenter2.props('data')).toBe(MOCK_ISSUES.nodes[1].description);

    const getCells = (row) => row.findAll('td').wrappers.map((td) => td.text());

    expect(getCells(tableRow1)).toEqual(['Issue 1', 'foobar', 'Open', 'This is a description']);
    expect(getCells(tableRow2)).toEqual([
      'Issue 2',
      'janedoe',
      'Closed',
      'This is another description',
    ]);
  });

  it('shows a "No data" message if the list of items provided is empty', () => {
    createWrapper({ data: { nodes: [] }, config: { fields: MOCK_FIELDS } });

    expect(wrapper.text()).toContain('No data found for this query');
  });
});
