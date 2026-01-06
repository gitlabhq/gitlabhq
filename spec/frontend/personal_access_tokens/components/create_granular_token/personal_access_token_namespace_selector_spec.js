import { GlCollapsibleListbox } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import PersonalAccessTokenNamespaceSelector from '~/personal_access_tokens/components/create_granular_token/personal_access_token_namespace_selector.vue';
import getUserGroupsAndProjects from '~/personal_access_tokens/graphql/get_user_groups_and_projects.query.graphql';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import {
  mockGroups,
  mockProjects,
  mockSearchGroupsAndProjectsQueryResponse,
} from '../../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('PersonalAccessTokenNamespaceSelector', () => {
  let wrapper;
  let mockApollo;

  const mockQueryHandler = jest.fn().mockResolvedValue(mockSearchGroupsAndProjectsQueryResponse);

  const selectedIds = ['gid://gitlab/Project/1', 'gid://gitlab/Group/1'];

  const emptySearchResults = {
    data: {
      projects: { nodes: [] },
      user: { id: 'gid://gitlab/User/123', groups: { nodes: [] } },
    },
  };

  const createComponent = ({ queryHandler = mockQueryHandler, props = {} } = {}) => {
    mockApollo = createMockApollo([[getUserGroupsAndProjects, queryHandler]]);

    window.gon = { current_user_id: 123 };

    wrapper = mountExtended(PersonalAccessTokenNamespaceSelector, {
      apolloProvider: mockApollo,
      propsData: {
        ...props,
      },
    });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findSelectedNamespaces = () => wrapper.findByTestId('selected-namespaces');
  const findRemoveButtons = () => wrapper.findAllByTestId('remove-namespace');

  const waitForQuery = async () => {
    jest.advanceTimersByTime(DEBOUNCE_DELAY);
    await waitForPromises();
  };

  beforeEach(() => {
    createComponent();
  });

  describe('rendering', () => {
    it('renders the collapsible listbox', () => {
      expect(findListbox().exists()).toBe(true);
      expect(findListbox().props('toggleText')).toBe('Add group or project');
    });

    it('renders error message when error prop is provided', () => {
      createComponent({ props: { error: 'At least one group or project is required.' } });

      expect(wrapper.text()).toContain('At least one group or project is required.');
    });

    it('renders empty text', () => {
      expect(wrapper.text()).toContain('No groups or projects added.');
    });
  });

  describe('GraphQL query', () => {
    it('fetches groups and projects on mount', async () => {
      await waitForQuery();

      expect(mockQueryHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/User/123',
        search: '',
      });
    });

    it('fetches data when search term changes', async () => {
      await findListbox().vm.$emit('search', 'test search');

      await waitForQuery();

      expect(mockQueryHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/User/123',
        search: 'test search',
      });
    });

    it('skips query when search term is too short', async () => {
      await findListbox().vm.$emit('search', 'a');

      await waitForQuery();

      expect(mockQueryHandler).not.toHaveBeenCalledWith({
        id: 'gid://gitlab/User/123',
        search: 'a',
      });
    });
  });

  describe('listbox items', () => {
    it('formats groups and projects into listbox items', async () => {
      await waitForQuery();

      expect(findListbox().props('items')).toEqual([
        {
          text: 'Groups',
          options: mockGroups.map((group) => ({
            value: group.id,
            text: group.fullPath,
          })),
        },
        {
          text: 'Projects',
          options: mockProjects.map((project) => ({
            value: project.id,
            text: project.fullPath,
          })),
        },
      ]);
    });

    it('shows no matches message when no results', async () => {
      const emptyQueryHandler = jest.fn().mockResolvedValue(emptySearchResults);

      createComponent({ queryHandler: emptyQueryHandler });

      await waitForQuery();

      expect(findListbox().text()).toContain('No matches found');
    });
  });

  describe('selected namespaces', () => {
    it('emits `input` event when group or project is selected', async () => {
      await waitForQuery();
      await findListbox().vm.$emit('select', selectedIds);

      expect(wrapper.emitted('input')).toEqual([[selectedIds]]);
    });

    it('displays selected groups', async () => {
      await waitForQuery();

      await findListbox().vm.$emit('select', selectedIds);

      expect(findSelectedNamespaces().text()).toContain('test-group-1');
      expect(findSelectedNamespaces().text()).toContain('2 subgroups');
      expect(findSelectedNamespaces().text()).toContain('5 projects');
    });

    it('displays selected projects', async () => {
      await waitForQuery();

      await findListbox().vm.$emit('select', selectedIds);

      expect(findSelectedNamespaces().text()).toContain('test-group-1/test-project-1');
    });

    it('displays the `aria-label` for remove buttons', async () => {
      await waitForQuery();

      await findListbox().vm.$emit('select', selectedIds);

      expect(findRemoveButtons().at(0).attributes('aria-label')).toBe(
        'Remove project Test Project 1',
      );
      expect(findRemoveButtons().at(1).attributes('aria-label')).toBe('Remove group Test Group 1');
    });

    it('removes item when remove button is clicked', async () => {
      await waitForQuery();

      await findListbox().vm.$emit('select', selectedIds);

      await findRemoveButtons().at(0).vm.$emit('click');

      expect(wrapper.emitted('input')[1]).toEqual([['gid://gitlab/Group/1']]);

      expect(findSelectedNamespaces().text()).not.toContain('test-group-1/test-project-1');
    });
  });

  describe('error handling', () => {
    it('shows fetch error when GraphQL query fails', async () => {
      const error = new Error('GraphQL error');
      const errorHandler = jest.fn().mockRejectedValue(error);

      createComponent({ queryHandler: errorHandler });

      await waitForQuery();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Error loading groups and projects. Please refresh page.',
        captureError: true,
        error,
      });
    });
  });
});
