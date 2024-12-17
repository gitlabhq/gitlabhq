import { nextTick } from 'vue';
import { GlSorting, GlFilteredSearch, GlAlert } from '@gitlab/ui';
import { cloneDeep } from 'lodash';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import TodosFilterBar from '~/todos/components/todos_filter_bar.vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';

describe('TodosFilterBar', () => {
  let wrapper;
  let trackingSpy;

  const mockGroupId = '33';
  const mockProjectId = '12';
  const mockAuthorId = '1';
  const mockTypeParam = {
    url: 'MergeRequest',
    api: 'MERGEREQUEST',
  };
  const mockActionParam = {
    url: '8',
    api: 'merge_train_removed',
  };

  const generateFilterToken = (type, data, id = 1) => ({
    type,
    value: {
      data,
      operator: '=',
    },
    id: `token-${id}`,
  });
  const generateFilterTokens = ({
    groupId = null,
    projectId = null,
    authorId = null,
    type = null,
    action = null,
  } = {}) => {
    let tokenIdx = 0;
    const tokens = [
      ['group', groupId],
      ['project', projectId],
      ['author', authorId],
      ['category', type],
      ['reason', action],
    ]
      .filter(([, value]) => value !== null)
      .map(([paramType, data]) => {
        tokenIdx += 1;
        return generateFilterToken(paramType, data, tokenIdx);
      });
    return tokens;
  };

  const findGlFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);
  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const findGlSorting = () => wrapper.findComponent(GlSorting);

  const getAuthorTokenProp = () =>
    findGlFilteredSearch()
      .props('availableTokens')
      .find((token) => token.type === 'author');

  const createComponent = () => {
    wrapper = shallowMountExtended(TodosFilterBar, {
      propsData: {
        todosStatus: ['pending'],
      },
    });
    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  };

  afterEach(() => {
    unmockTracking();
  });

  it('passes the correct props to the `GlFilteredSearch` component', () => {
    createComponent();
    const authorToken = getAuthorTokenProp();

    expect(cloneDeep(findGlFilteredSearch().props())).toEqual(
      expect.objectContaining({
        termsAsTokens: true,
        placeholder: 'Filter to-do items',
        searchTextOptionLabel: 'Raw text search is not currently supported',
      }),
    );
    expect(authorToken.status).toStrictEqual(['pending']);
  });

  it('updates the author token status', async () => {
    createComponent();
    wrapper.setProps({ todosStatus: ['done'] });
    await nextTick();
    const authorToken = getAuthorTokenProp();

    expect(authorToken.status).toStrictEqual(['done']);
  });

  it('emits the `filters-changed` event and updates the URL when filters are submitted', () => {
    createComponent();

    findGlFilteredSearch().vm.$emit(
      'input',
      generateFilterTokens({
        groupId: mockGroupId,
        projectId: mockProjectId,
        authorId: mockAuthorId,
        type: mockTypeParam.api,
        action: mockActionParam.api,
      }),
    );
    findGlFilteredSearch().vm.$emit('submit');

    expect(wrapper.emitted('filters-changed')).toEqual([
      [
        {
          groupId: [mockGroupId],
          projectId: [mockProjectId],
          authorId: [mockAuthorId],
          type: [mockTypeParam.api],
          action: [mockActionParam.api],
          sort: 'CREATED_DESC',
        },
      ],
    ]);
    expect(window.location.search).toBe(
      `?group_id=${mockGroupId}&project_id=${mockProjectId}&author_id=${mockAuthorId}&type=${mockTypeParam.url}&action_id=${mockActionParam.url}`,
    );
  });

  it('emits telemetry events upon selecting new filters (not submit!)', async () => {
    createComponent();

    findGlFilteredSearch().vm.$emit(
      'input',
      generateFilterTokens({
        groupId: mockGroupId,
      }),
    );
    await nextTick();
    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'filter_todo_list', {
      label: 'filter_groupId',
    });

    findGlFilteredSearch().vm.$emit(
      'input',
      generateFilterTokens({
        projectId: mockProjectId,
      }),
    );
    await nextTick();
    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'filter_todo_list', {
      label: 'filter_projectId',
    });

    findGlFilteredSearch().vm.$emit(
      'input',
      generateFilterTokens({
        authorId: mockAuthorId,
      }),
    );
    await nextTick();
    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'filter_todo_list', {
      label: 'filter_authorId',
    });

    findGlFilteredSearch().vm.$emit(
      'input',
      generateFilterTokens({
        type: mockTypeParam.api,
      }),
    );
    await nextTick();
    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'filter_todo_list', {
      label: 'filter_type',
    });

    findGlFilteredSearch().vm.$emit(
      'input',
      generateFilterTokens({
        action: mockActionParam.api,
      }),
    );
    await nextTick();
    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'filter_todo_list', {
      label: 'filter_action',
    });

    expect(trackingSpy).toHaveBeenCalledTimes(5);
  });

  it('does not emit telemetry events on changing a filter', async () => {
    createComponent();

    findGlFilteredSearch().vm.$emit(
      'input',
      generateFilterTokens({
        groupId: mockGroupId,
      }),
    );
    await nextTick();
    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'filter_todo_list', {
      label: 'filter_groupId',
    });
    expect(trackingSpy).toHaveBeenCalledTimes(1);

    findGlFilteredSearch().vm.$emit(
      'input',
      generateFilterTokens({
        groupId: mockGroupId + mockGroupId,
      }),
    );
    await nextTick();
    expect(trackingSpy).toHaveBeenCalledTimes(1);
  });

  it('does not emit telemetry events on removing a filter', async () => {
    createComponent();

    findGlFilteredSearch().vm.$emit(
      'input',
      generateFilterTokens({
        groupId: mockGroupId,
        projectId: mockProjectId,
      }),
    );
    await nextTick();
    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'filter_todo_list', {
      label: 'filter_groupId',
    });
    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'filter_todo_list', {
      label: 'filter_projectId',
    });
    expect(trackingSpy).toHaveBeenCalledTimes(2);

    findGlFilteredSearch().vm.$emit(
      'input',
      generateFilterTokens({
        groupId: mockGroupId,
      }),
    );
    await nextTick();
    expect(trackingSpy).toHaveBeenCalledTimes(2);
  });

  it('shows a warning message when trying to text-search and only submits the supported filter tokens', async () => {
    createComponent();
    expect(findGlAlert().exists()).toBe(false);

    findGlFilteredSearch().vm.$emit('input', [
      ...generateFilterTokens({ groupId: mockGroupId }),
      generateFilterToken('filtered-search-term', 'my todo', 5),
    ]);
    findGlFilteredSearch().vm.$emit('submit');
    await nextTick();

    const warningAlert = findGlAlert();
    expect(warningAlert.exists()).toBe(true);
    expect(warningAlert.props('variant')).toBe('warning');
    expect(warningAlert.text()).toBe(
      'Raw text search is not currently supported. Please use the available search tokens.',
    );
    expect(wrapper.emitted('filters-changed')).toEqual([
      [
        {
          groupId: [mockGroupId],
          projectId: [],
          authorId: [],
          type: [],
          action: [],
          sort: 'CREATED_DESC',
        },
      ],
    ]);
  });

  it('emits the `filter-changed` event when filters are reset', async () => {
    createComponent();
    findGlFilteredSearch().vm.$emit('clear');

    await nextTick();

    expect(wrapper.emitted('filters-changed')).toEqual([
      [
        {
          groupId: [],
          projectId: [],
          authorId: [],
          type: [],
          action: [],
          sort: 'CREATED_DESC',
        },
      ],
    ]);
  });

  it('emits the `filter-changed` event and updates the URL when the sort order is changed', () => {
    createComponent();
    findGlSorting().vm.$emit('sortByChange', 'UPDATED');

    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'sort_todo_list', {
      label: 'UPDATED_DESC',
    });
    expect(wrapper.emitted('filters-changed')[0][0].sort).toBe('UPDATED_DESC');
    expect(window.location.search).toBe('?sort=UPDATED_DESC');
    unmockTracking();
  });

  it('emits the `filter-changed` event and updates the URL when the sort direction is changed', () => {
    createComponent();
    findGlSorting().vm.$emit('sortDirectionChange', true);

    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'sort_todo_list', {
      label: 'CREATED_ASC',
    });
    expect(wrapper.emitted('filters-changed')[0][0].sort).toBe('CREATED_ASC');
    expect(window.location.search).toBe('?sort=CREATED_ASC');

    findGlSorting().vm.$emit('sortDirectionChange', false);

    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'sort_todo_list', {
      label: 'CREATED_DESC',
    });
    expect(wrapper.emitted('filters-changed')[1][0].sort).toBe('CREATED_DESC');
    expect(window.location.search).toBe('');
  });

  it('removes search params from the URL if the corresponding filters are not set', () => {
    createComponent();
    findGlFilteredSearch().vm.$emit(
      'input',
      generateFilterTokens({
        groupId: mockGroupId,
        projectId: mockProjectId,
        authorId: mockAuthorId,
      }),
    );
    findGlFilteredSearch().vm.$emit('submit');
    findGlSorting().vm.$emit('sortByChange', 'LABEL_PRIORITY');
    findGlSorting().vm.$emit('sortDirectionChange', true);

    expect(window.location.search).toBe(
      '?group_id=33&project_id=12&author_id=1&sort=LABEL_PRIORITY_ASC',
    );

    findGlFilteredSearch().vm.$emit('input', generateFilterTokens({ groupId: mockGroupId }));
    findGlFilteredSearch().vm.$emit('submit');

    expect(window.location.search).toBe('?group_id=33&sort=LABEL_PRIORITY_ASC');
  });

  describe('handling of other search params', () => {
    it('keeps search params that are not controlled by this component', () => {
      setWindowLocation('?state=done');
      createComponent();

      findGlFilteredSearch().vm.$emit('input', generateFilterTokens({ groupId: mockGroupId }));
      findGlFilteredSearch().vm.$emit('submit');

      expect(window.location.search).toBe('?state=done&group_id=33');
    });
  });

  describe('initializing filter values from the URL search params', () => {
    it('initializes the filters from the values passed as search params', () => {
      setWindowLocation(
        `?group_id=${mockGroupId}&project_id=${mockProjectId}&author_id=${mockAuthorId}&type=${mockTypeParam.url}&action_id=${mockActionParam.url}&sort=UPDATED_ASC`,
      );
      createComponent();

      expect(wrapper.emitted('filters-changed')).toEqual([
        [
          {
            groupId: [mockGroupId],
            projectId: [mockProjectId],
            authorId: [mockAuthorId],
            type: [mockTypeParam.api],
            action: [mockActionParam.api],
            sort: 'UPDATED_ASC',
          },
        ],
      ]);
    });

    it('defaults to CREATED sort param if an illegal value is provided in the URL', () => {
      setWindowLocation('?sort=foo_bar');
      createComponent();

      expect(wrapper.emitted('filters-changed')[0][0].sort).toBe('CREATED_DESC');
    });

    it('defaults to descending order if not specified in the URL (eg. supporting the legacy `?sort=label_priority` parameter)', () => {
      setWindowLocation('?sort=label_priority');
      createComponent();

      expect(wrapper.emitted('filters-changed')[0][0].sort).toBe('LABEL_PRIORITY_DESC');
    });

    it('ignores illegal category and reason IDs', () => {
      setWindowLocation('?type=Foo&action_id=9000');
      createComponent();

      expect(wrapper.emitted('filters-changed')).toBeUndefined();
    });
  });
});
