import { nextTick } from 'vue';
import { GlSorting, GlFilteredSearch, GlAlert } from '@gitlab/ui';
import { cloneDeep } from 'lodash';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TodosFilterBar from '~/todos/components/todos_filter_bar.vue';

describe('TodosFilterBar', () => {
  let wrapper;

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

  beforeEach(createComponent);

  it('passes the correct props to the `GlFilteredSearch` component', () => {
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
    wrapper.setProps({ todosStatus: ['done'] });
    await nextTick();
    const authorToken = getAuthorTokenProp();

    expect(authorToken.status).toStrictEqual(['done']);
  });

  it('emits the `filters-changed` when filters are submitted', () => {
    const groupId = '33';
    const projectId = '12';
    const authorId = '1';
    const type = 'ISSUE';
    const action = 'assigned';

    findGlFilteredSearch().vm.$emit(
      'input',
      generateFilterTokens({ groupId, projectId, authorId, type, action }),
    );
    findGlFilteredSearch().vm.$emit('submit');

    expect(wrapper.emitted('filters-changed')).toEqual([
      [
        {
          groupId: [groupId],
          projectId: [projectId],
          authorId: [authorId],
          type: [type],
          action: [action],
          sort: 'CREATED_DESC',
        },
      ],
    ]);
  });

  it('shows a warning message when trying to text-search and only submits the supported filter tokens', async () => {
    const groupId = '33';

    expect(findGlAlert().exists()).toBe(false);

    findGlFilteredSearch().vm.$emit('input', [
      ...generateFilterTokens({ groupId }),
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
          groupId: [groupId],
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

  it('emits the `filter-changed` event when the sort order is changed', () => {
    findGlSorting().vm.$emit('sortByChange', 'UPDATED');

    expect(wrapper.emitted('filters-changed')[0][0].sort).toBe('UPDATED_DESC');
  });

  it('emits the `filter-changed` event when the sort direction is changed', () => {
    findGlSorting().vm.$emit('sortDirectionChange', true);

    expect(wrapper.emitted('filters-changed')[0][0].sort).toBe('CREATED_ASC');

    findGlSorting().vm.$emit('sortDirectionChange', false);

    expect(wrapper.emitted('filters-changed')[1][0].sort).toBe('CREATED_DESC');
  });
});
