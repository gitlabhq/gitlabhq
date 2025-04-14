import { GlSkeletonLoader } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GlqlActions from '~/glql/components/common/actions.vue';
import IssuablePresenter from '~/glql/components/presenters/issuable.vue';
import ListPresenter from '~/glql/components/presenters/list.vue';
import StatePresenter from '~/glql/components/presenters/state.vue';
import HtmlPresenter from '~/glql/components/presenters/html.vue';
import UserPresenter from '~/glql/components/presenters/user.vue';
import Presenter from '~/glql/core/presenter';
import { MOCK_FIELDS, MOCK_ISSUES } from '../../mock_data';

describe('ListPresenter', () => {
  let wrapper;

  const createWrapper = ({ data, config, ...moreProps }, mountFn = shallowMountExtended) => {
    wrapper = mountFn(ListPresenter, {
      provide: {
        presenter: new Presenter().init({ data, config }),
        queryKey: 'glql_key',
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

    const issuePresenter1 = listItem1.findComponent(IssuablePresenter);
    const issuePresenter2 = listItem2.findComponent(IssuablePresenter);
    const userPresenter1 = listItem1.findComponent(UserPresenter);
    const userPresenter2 = listItem2.findComponent(UserPresenter);
    const statePresenter1 = listItem1.findComponent(StatePresenter);
    const statePresenter2 = listItem2.findComponent(StatePresenter);
    const htmlPresenter1 = listItem1.findComponent(HtmlPresenter);
    const htmlPresenter2 = listItem2.findComponent(HtmlPresenter);

    expect(issuePresenter1.props('data')).toBe(MOCK_ISSUES.nodes[0]);
    expect(issuePresenter2.props('data')).toBe(MOCK_ISSUES.nodes[1]);
    expect(userPresenter1.props('data')).toBe(MOCK_ISSUES.nodes[0].author);
    expect(userPresenter2.props('data')).toBe(MOCK_ISSUES.nodes[1].author);
    expect(statePresenter1.props('data')).toBe(MOCK_ISSUES.nodes[0].state);
    expect(statePresenter2.props('data')).toBe(MOCK_ISSUES.nodes[1].state);
    expect(htmlPresenter1.props('data')).toBe(MOCK_ISSUES.nodes[0].description);
    expect(htmlPresenter2.props('data')).toBe(MOCK_ISSUES.nodes[1].description);

    expect(htmlPresenter1.props('data')).toBe(MOCK_ISSUES.nodes[0].description);
    expect(htmlPresenter2.props('data')).toBe(MOCK_ISSUES.nodes[1].description);

    expect(listItem1.text()).toEqual('Issue 1 (#1) @foobar ·  Open · This is a description');
    expect(listItem2.text()).toEqual(
      'Issue 2 (#2 - closed) @janedoe ·  Closed · This is another description',
    );
  });

  it('renders a ul by default', () => {
    createWrapper({ data: MOCK_ISSUES, config: { fields: MOCK_FIELDS } });

    expect(wrapper.find('ul')).toBeDefined();
  });

  it('renders skeleton loader if isPreview is true', () => {
    createWrapper(
      { data: MOCK_ISSUES, config: { fields: MOCK_FIELDS }, isPreview: true },
      mountExtended,
    );

    expect(wrapper.findAllComponents(GlSkeletonLoader)).toHaveLength(5);
  });

  it('renders actions', () => {
    createWrapper({ data: MOCK_ISSUES, config: { fields: MOCK_FIELDS } }, mountExtended);
    expect(wrapper.findComponent(GlqlActions).props()).toEqual({
      modalTitle: 'GLQL list',
      showCopyContents: true,
    });
  });

  it('renders a footer text', () => {
    createWrapper({ data: MOCK_ISSUES, config: { fields: MOCK_FIELDS } }, mountExtended);

    expect(wrapper.findByTestId('footer').text()).toEqual('View powered by GLQL');
  });

  it('renders a ol if passed as a prop', () => {
    createWrapper({ data: MOCK_ISSUES, config: { fields: MOCK_FIELDS }, listType: 'ol' });

    expect(wrapper.find('ol')).toBeDefined();
  });

  it('shows a "No data" message if the list of items provided is empty', () => {
    createWrapper({ data: { nodes: [] }, config: { fields: MOCK_FIELDS } }, mountExtended);

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
