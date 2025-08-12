import { GlSkeletonLoader } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import IssuablePresenter from '~/glql/components/presenters/issuable.vue';
import ListPresenter from '~/glql/components/presenters/list.vue';
import StatePresenter from '~/glql/components/presenters/state.vue';
import HtmlPresenter from '~/glql/components/presenters/html.vue';
import UserPresenter from '~/glql/components/presenters/user.vue';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { MOCK_FIELDS, MOCK_ISSUES } from '../../mock_data';

describe('ListPresenter', () => {
  let wrapper;

  useMockLocationHelper();

  beforeEach(() => {
    window.location.href = 'https://gitlab.com/gitlab-org/gitlab-shell/-/issues/1';
    window.location.origin = 'https://gitlab.com';
  });

  const createWrapper = ({ data, fields, ...moreProps }, mountFn = shallowMountExtended) => {
    wrapper = mountFn(ListPresenter, {
      propsData: { data, fields, ...moreProps },
    });
  };

  it('renders a list of items presented by appropriate presenters', () => {
    createWrapper({ data: MOCK_ISSUES, fields: MOCK_FIELDS }, mountExtended);

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

    expect(listItem1.text()).toEqual(
      'Issue 1 (gitlab-test#1) @foobar ·  Open · This is a description',
    );
    expect(listItem2.text()).toEqual(
      'Issue 2 (gitlab-test#2 - closed) @janedoe ·  Closed · This is another description',
    );
  });

  it('renders a ul by default', () => {
    createWrapper({ data: MOCK_ISSUES, fields: MOCK_FIELDS });

    expect(wrapper.find('ul')).toBeDefined();
  });

  it('renders skeleton loader if loading is true', () => {
    createWrapper({ data: { nodes: [] }, fields: MOCK_FIELDS, loading: true }, mountExtended);

    expect(wrapper.findAllComponents(GlSkeletonLoader)).toHaveLength(5);
  });

  it('renders a ol if passed as a prop', () => {
    createWrapper({ data: MOCK_ISSUES, fields: MOCK_FIELDS, listType: 'ol' });

    expect(wrapper.find('ol')).toBeDefined();
  });
});
