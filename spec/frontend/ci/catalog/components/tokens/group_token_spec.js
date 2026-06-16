import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import GroupToken from '~/ci/catalog/components/tokens/group_token.vue';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import groupsAutocompleteQuery from '~/graphql_shared/queries/groups_autocomplete.query.graphql';
import getGroupNamesByIdsQuery from '~/ci/catalog/graphql/queries/get_groups_by_ids.query.graphql';

Vue.use(VueApollo);

jest.mock('~/alert');

const mockGroups = [
  {
    id: 'gid://gitlab/Group/1',
    name: 'GitLab Org',
    fullPath: 'gitlab-org',
    fullName: 'GitLab Org',
    avatarUrl: null,
  },
  {
    id: 'gid://gitlab/Group/2',
    name: 'Frontend',
    fullPath: 'gitlab-org/frontend',
    fullName: 'GitLab Org / Frontend',
    avatarUrl: null,
  },
  {
    id: 'gid://gitlab/Group/3',
    name: 'Backend',
    fullPath: 'gitlab-org/backend',
    fullName: 'GitLab Org / Backend',
    avatarUrl: null,
  },
];

const mockGroupsResponse = {
  data: {
    groups: {
      nodes: mockGroups,
    },
  },
};

describe('GroupToken', () => {
  let wrapper;
  let queryHandler;
  let groupsByIdsHandler;

  const defaultProps = {
    config: { type: 'group', multiSelect: true },
    value: { data: '', operator: '||' },
    active: false,
  };

  const findBaseToken = () => wrapper.findComponent(BaseToken);

  const triggerFetchSuggestions = async (search = '') => {
    findBaseToken().vm.$emit('fetch-suggestions', search);
    await waitForPromises();
  };

  const createComponent = ({ props = {}, handler, idHandler } = {}) => {
    const mockApollo = createMockApollo([
      [groupsAutocompleteQuery, handler || queryHandler],
      [getGroupNamesByIdsQuery, idHandler || groupsByIdsHandler],
    ]);

    wrapper = shallowMount(GroupToken, {
      apolloProvider: mockApollo,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  beforeEach(() => {
    queryHandler = jest.fn().mockResolvedValue(mockGroupsResponse);
    groupsByIdsHandler = jest.fn().mockResolvedValue(mockGroupsResponse);
  });

  it('renders the base token with correct props', () => {
    createComponent();

    expect(findBaseToken().props()).toMatchObject({
      active: false,
      config: defaultProps.config,
      value: defaultProps.value,
      suggestions: [],
      suggestionsLoading: false,
    });
  });

  describe('fetching groups', () => {
    it('fetches groups when base token emits fetch-suggestions', async () => {
      createComponent();

      await triggerFetchSuggestions('gitlab');

      expect(queryHandler).toHaveBeenCalledWith({ search: 'gitlab' });
    });

    it('uses numeric ID as value and fullName as text', async () => {
      createComponent();

      await triggerFetchSuggestions();

      expect(findBaseToken().props('suggestions')).toEqual([
        { value: '1', text: 'GitLab Org' },
        { value: '2', text: 'GitLab Org / Frontend' },
        { value: '3', text: 'GitLab Org / Backend' },
      ]);
    });

    it('sets suggestionsLoading while fetching', async () => {
      createComponent();

      expect(findBaseToken().props('suggestionsLoading')).toBe(false);

      findBaseToken().vm.$emit('fetch-suggestions', '');
      await nextTick();

      expect(findBaseToken().props('suggestionsLoading')).toBe(true);

      await waitForPromises();
      expect(findBaseToken().props('suggestionsLoading')).toBe(false);
    });

    it('passes empty suggestions for empty response', async () => {
      const emptyHandler = jest.fn().mockResolvedValue({
        data: { groups: { nodes: [] } },
      });
      createComponent({ handler: emptyHandler });

      await triggerFetchSuggestions();

      expect(findBaseToken().props('suggestions')).toEqual([]);
    });

    it('shows an alert on error', async () => {
      const errorHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));
      createComponent({ handler: errorHandler });

      await triggerFetchSuggestions();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was an error fetching groups.',
      });
    });
  });

  describe('initial value resolution', () => {
    it('resolves initial IDs to display names on mount', async () => {
      const idHandler = jest.fn().mockResolvedValue({
        data: {
          groups: {
            nodes: [
              { id: 'gid://gitlab/Group/1', fullName: 'GitLab Org' },
              { id: 'gid://gitlab/Group/2', fullName: 'GitLab Org / Frontend' },
            ],
          },
        },
      });

      createComponent({
        props: { value: { data: ['1', '2'], operator: '||' } },
        idHandler,
      });

      await waitForPromises();

      expect(idHandler).toHaveBeenCalledWith({
        ids: ['gid://gitlab/Group/1', 'gid://gitlab/Group/2'],
      });
    });

    it('does not fetch when value data is empty', () => {
      createComponent();

      expect(groupsByIdsHandler).not.toHaveBeenCalled();
    });

    it('shows an alert on error', async () => {
      const idHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

      createComponent({
        props: { value: { data: ['1'], operator: '||' } },
        idHandler,
      });

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was an error fetching groups.',
      });
    });
  });
});
