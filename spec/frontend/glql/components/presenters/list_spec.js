import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import ListPresenter from '~/glql/components/presenters/list.vue';
import TextPresenter from '~/glql/components/presenters/text.vue';
import LinkPresenter from '~/glql/components/presenters/link.vue';
import Presenter from '~/glql/core/presenter';
import { MOCK_ISSUES, MOCK_FIELDS } from '../../mock_data';

describe('ListPresenter', () => {
  let wrapper;

  const createWrapper = ({ data, config, ...moreProps }, mountFn = shallowMountExtended) => {
    wrapper = mountFn(ListPresenter, {
      provide: {
        presenter: new Presenter().init({ data, config }),
      },
      propsData: { data, config, ...moreProps },
    });
  };

  const mockConsoleError = () => {
    jest.spyOn(console, 'error').mockImplementation(() => {});
  };

  it('renders a list of items presented by appropriate presenters', () => {
    createWrapper({ data: MOCK_ISSUES, config: { fields: MOCK_FIELDS } }, mountExtended);

    const listItem1 = wrapper.findByTestId('list-item-0');
    const listItem2 = wrapper.findByTestId('list-item-1');

    const linkPresenters1 = listItem1.findAllComponents(LinkPresenter);
    const linkPresenters2 = listItem2.findAllComponents(LinkPresenter);
    const textPresenter1 = listItem1.findComponent(TextPresenter);
    const textPresenter2 = listItem2.findComponent(TextPresenter);

    expect(linkPresenters1).toHaveLength(2);
    expect(linkPresenters2).toHaveLength(2);

    expect(linkPresenters1.at(0).props('data')).toBe(MOCK_ISSUES.nodes[0]);
    expect(linkPresenters1.at(1).props('data')).toBe(MOCK_ISSUES.nodes[0].author);
    expect(linkPresenters2.at(0).props('data')).toBe(MOCK_ISSUES.nodes[1]);
    expect(linkPresenters2.at(1).props('data')).toBe(MOCK_ISSUES.nodes[1].author);

    expect(textPresenter1.props('data')).toBe(MOCK_ISSUES.nodes[0].state);
    expect(textPresenter2.props('data')).toBe(MOCK_ISSUES.nodes[1].state);

    expect(listItem1.text()).toEqual('Issue 1 - foobar - opened');
    expect(listItem2.text()).toEqual('Issue 2 - janedoe - closed');
  });

  it('renders a ul by default', () => {
    createWrapper({ data: MOCK_ISSUES, config: { fields: MOCK_FIELDS } });

    expect(wrapper.find('ul')).toBeDefined();
  });

  it('renders a ol if passed as a prop', () => {
    createWrapper({ data: MOCK_ISSUES, config: { fields: MOCK_FIELDS }, listType: 'ol' });

    expect(wrapper.find('ol')).toBeDefined();
  });

  it('shows a "No data" message if the list of items provided is empty', () => {
    createWrapper({ data: { nodes: [] }, config: { fields: MOCK_FIELDS } });

    expect(wrapper.text()).toContain('No data found for this query');
  });

  it.each`
    scenario                         | props                                                                      | fieldNameWithError
    ${'for data without a nodes'}    | ${{ config: {}, data: {} }}                                                | ${'data'}
    ${'for config without a fields'} | ${{ data: MOCK_ISSUES, config: {} }}                                       | ${'config'}
    ${'for incorrect listType'}      | ${{ data: MOCK_ISSUES, config: { fields: MOCK_FIELDS }, listType: 'div' }} | ${'listType'}
  `(
    'shows a prop validation error if any other listType is passed',
    ({ props, fieldNameWithError }) => {
      mockConsoleError();
      createWrapper(props);

      // eslint-disable-next-line no-console
      expect(console.error.mock.calls[0][0]).toContain(
        `[Vue warn]: Invalid prop: custom validator check failed for prop "${fieldNameWithError}"`,
      );
    },
  );
});
