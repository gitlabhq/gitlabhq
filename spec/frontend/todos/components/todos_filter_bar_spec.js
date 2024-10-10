import { nextTick } from 'vue';
import { GlSorting, GlFilteredSearch, GlAlert } from '@gitlab/ui';
import { cloneDeep } from 'lodash';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TodosFilterBar from '~/todos/components/todos_filter_bar.vue';

describe('TodosFilterBar', () => {
  let wrapper;

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
  };

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

    expect(wrapper.emitted('filters-changed')[0][0].sort).toBe('UPDATED_DESC');
    expect(window.location.search).toBe('?sort=UPDATED_DESC');
  });

  it('emits the `filter-changed` event and updates the URL when the sort direction is changed', () => {
    createComponent();
    findGlSorting().vm.$emit('sortDirectionChange', true);

    expect(wrapper.emitted('filters-changed')[0][0].sort).toBe('CREATED_ASC');
    expect(window.location.search).toBe('?sort=CREATED_ASC');

    findGlSorting().vm.$emit('sortDirectionChange', false);

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

  describe('initializing filter values from the URL search params', () => {
    beforeEach(() => {
      Object.defineProperty(window, 'location', {
        writable: true,
        value: {
          hash: '',
          search: '',
        },
      });
    });

    it('initializes the filters from the values passed as search params', () => {
      window.location.search = `?group_id=${mockGroupId}&project_id=${mockProjectId}&author_id=${mockAuthorId}&type=${mockTypeParam.url}&action_id=${mockActionParam.url}&sort=UPDATED_ASC`;
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
      window.location.search = '?sort=foo_bar';
      createComponent();

      expect(wrapper.emitted('filters-changed')[0][0].sort).toBe('CREATED_DESC');
    });

    it('defaults to descending order if not specified in the URL (eg. supporting the legacy `?sort=label_priority` parameter)', () => {
      window.location.search = '?sort=label_priority';
      createComponent();

      expect(wrapper.emitted('filters-changed')[0][0].sort).toBe('LABEL_PRIORITY_DESC');
    });

    it('ignores illegal category and reason IDs', () => {
      window.location.search = '?type=Foo&action_id=9000';
      createComponent();

      expect(wrapper.emitted('filters-changed')).toBeUndefined();
    });
  });
});
