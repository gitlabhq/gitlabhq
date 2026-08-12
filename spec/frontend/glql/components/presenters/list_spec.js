import { GlSkeletonLoader } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FieldPresenter from '~/glql/components/presenters/field.vue';
import IssuablePresenter from '~/glql/components/presenters/issuable.vue';
import ListPresenter from '~/glql/components/presenters/list.vue';
import ProjectPresenter from '~/glql/components/presenters/project.vue';
import StatePresenter from '~/glql/components/presenters/state.vue';
import HtmlPresenter from '~/glql/components/presenters/html.vue';
import UserPresenter from '~/glql/components/presenters/user.vue';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { MOCK_FIELDS, MOCK_ISSUES, MOCK_PROJECT } from '../../mock_data';

describe('ListPresenter', () => {
  let wrapper;

  useMockLocationHelper();

  beforeEach(() => {
    window.location.origin = 'https://gitlab.com';
    document.body.dataset.projectFullPath = 'gitlab-org/gitlab-shell';
  });

  afterEach(() => {
    delete document.body.dataset.projectFullPath;
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

  it('does not render title heading when fields do not include title', () => {
    const fieldsWithoutTitle = MOCK_FIELDS.filter((f) => f.key !== 'title');
    createWrapper({ data: MOCK_ISSUES, fields: fieldsWithoutTitle }, mountExtended);

    expect(wrapper.find('h3').exists()).toBe(false);
  });

  it('renders all fields when there is no title field', () => {
    const fieldsWithoutTitle = MOCK_FIELDS.filter((f) => f.key !== 'title');
    createWrapper({ data: MOCK_ISSUES, fields: fieldsWithoutTitle }, mountExtended);

    const listItem = wrapper.findByTestId('list-item-0');
    const fieldPresenters = listItem.findAllComponents(FieldPresenter);
    const fieldKeys = fieldPresenters.wrappers.map((w) => w.props('fieldKey'));

    fieldsWithoutTitle.forEach((field) => {
      expect(fieldKeys).toContain(field.key);
    });
  });

  describe('per-type title alias', () => {
    const projectFields = [
      { key: 'name', label: 'Name', name: 'name' },
      { key: 'updatedAt', label: 'Updated', name: 'updatedAt' },
    ];
    const projectData = {
      nodes: [
        { ...MOCK_PROJECT, id: 'gid://gitlab/Project/1', name: 'Wget2', updatedAt: '2026-05-22' },
      ],
    };

    it('promotes the type-aliased field to the title heading for Project items', () => {
      createWrapper({ data: projectData, fields: projectFields }, mountExtended);

      expect(wrapper.find('h3').exists()).toBe(true);
      expect(wrapper.find('h3').findComponent(ProjectPresenter).exists()).toBe(true);
    });

    it('hides the title-aliased field from the inline row', () => {
      createWrapper({ data: projectData, fields: projectFields }, mountExtended);

      const inlinePresenters = wrapper
        .findByTestId('list-item-0')
        .findAllComponents(FieldPresenter)
        .wrappers.filter((w) => w.props('variant') === 'compact');
      const inlineKeys = inlinePresenters.map((w) => w.props('fieldKey'));

      expect(inlineKeys).not.toContain('name');
      expect(inlineKeys).toContain('updatedAt');
    });
  });

  it('passes field key for data access and presenter key for dispatch on aliased fields', () => {
    const aliasedField = {
      key: 'p50',
      field: 'durationQuantile',
      label: 'Duration P50',
      type: 'metric',
      parameters: { quantile: 0.5 },
    };

    createWrapper({
      data: {
        nodes: [
          {
            __typename: 'FinishedPipelinesAggregationResponseDimensions',
            id: '1',
            p50: 3661,
          },
        ],
      },
      fields: [aliasedField],
    });

    const fieldPresenter = wrapper.findComponent(FieldPresenter);
    expect(fieldPresenter.props('fieldKey')).toBe('p50');
    expect(fieldPresenter.props('presenterKey')).toBe('durationQuantile');
  });

  it('renders formatted values, not "None", for aliased parameterised fields', () => {
    const fields = [
      {
        key: 'Monthly',
        field: 'timestamp',
        label: 'Monthly',
        name: 'timestamp',
        type: 'dimension',
        parameters: { granularity: 'monthly' },
      },
      {
        key: 'p50',
        field: 'durationQuantile',
        label: 'Duration P50',
        name: 'durationQuantile',
        type: 'metric',
        parameters: { quantile: 0.5 },
      },
    ];

    createWrapper(
      { data: { nodes: [{ id: '1', Monthly: '2026-06-01', p50: 3661 }] }, fields },
      mountExtended,
    );

    expect(wrapper.findByTestId('list-item-0').text()).toBe('Jun 1, 2026 · 1h 1m 1s');
  });

  it('passes compact variant to field presenters', () => {
    createWrapper({ data: MOCK_ISSUES, fields: MOCK_FIELDS }, mountExtended);

    const listItem = wrapper.findByTestId('list-item-0');
    const fieldPresenters = listItem.findAllComponents(FieldPresenter);
    const nonTitlePresenters = fieldPresenters.wrappers.filter(
      (w) => w.props('fieldKey') !== 'title',
    );

    nonTitlePresenters.forEach((fp) => {
      expect(fp.props('variant')).toBe('compact');
    });
  });
});
