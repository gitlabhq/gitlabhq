import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import GranularNamespaceSelector from '~/vue_shared/access_tokens/components/granular_namespace_selector.vue';
import PersonalAccessTokenNamespaceSelector from '~/personal_access_tokens/components/create_granular_token/personal_access_token_namespace_selector.vue';
import getUserGroupsAndProjects from '~/personal_access_tokens/graphql/get_user_groups_and_projects.query.graphql';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import {
  mockNonMemberProject,
  mockNonMemberGroup,
  mockFullPathProjectQueryResponse,
  mockFullPathGroupQueryResponse,
  mockSearchGroupsAndProjectsQueryResponse,
} from '../../mock_data';
import { mockGroups, mockProjects } from '../../../vue_shared/access_tokens/mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('PersonalAccessTokenNamespaceSelector', () => {
  let wrapper;
  let mockApollo;

  const mockQueryHandler = jest.fn().mockResolvedValue(mockSearchGroupsAndProjectsQueryResponse);

  const createComponent = ({ queryHandler = mockQueryHandler, props = {} } = {}) => {
    mockApollo = createMockApollo([[getUserGroupsAndProjects, queryHandler]]);

    window.gon = { current_user_id: 123 };

    wrapper = shallowMountExtended(PersonalAccessTokenNamespaceSelector, {
      apolloProvider: mockApollo,
      propsData: {
        ...props,
      },
    });
  };

  const findSelector = () => wrapper.findComponent(GranularNamespaceSelector);
  const search = (term) => findSelector().vm.$emit('search', term);

  const waitForQuery = async () => {
    jest.advanceTimersByTime(DEBOUNCE_DELAY);
    await waitForPromises();
  };

  beforeEach(() => {
    createComponent();
  });

  describe('rendering', () => {
    it('explains that a full path finds namespaces the user is not a member of', () => {
      expect(findSelector().props('searchHint')).toBe(
        "Enter a full path to find groups or projects you're not a member of.",
      );
    });

    it('marks the namespace selector as loading while the query runs', async () => {
      jest.advanceTimersByTime(DEBOUNCE_DELAY);
      await nextTick();

      expect(findSelector().props('isLoading')).toBe(true);

      await waitForPromises();

      expect(findSelector().props('isLoading')).toBe(false);
    });

    describe('with a value and an error', () => {
      beforeEach(() => {
        createComponent({
          props: {
            value: [mockGroups[0]],
            error: 'At least one group or project is required.',
          },
        });
      });

      it('passes them through to the namespace selector', () => {
        expect(findSelector().props('value')).toEqual([mockGroups[0]]);
        expect(findSelector().props('error')).toBe('At least one group or project is required.');
      });
    });
  });

  describe('GraphQL query', () => {
    it('fetches groups and projects on mount', async () => {
      await waitForQuery();

      expect(mockQueryHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/User/123',
        search: '',
        fullPath: '',
        hasSearch: false,
      });
    });

    it('fetches data when search term changes', async () => {
      await search('test search');

      await waitForQuery();

      expect(mockQueryHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/User/123',
        search: 'test search',
        fullPath: 'test search',
        hasSearch: true,
      });
    });

    it('trims the search term before looking it up as a full path', async () => {
      await search('  test search  ');

      await waitForQuery();

      expect(mockQueryHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/User/123',
        search: '  test search  ',
        fullPath: 'test search',
        hasSearch: true,
      });
    });

    it('does not look up a full path when the search term is only whitespace', async () => {
      await search('   ');

      await waitForQuery();

      expect(mockQueryHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/User/123',
        search: '   ',
        fullPath: '',
        hasSearch: false,
      });
    });

    it('skips query when search term is too short', async () => {
      await search('a');

      await waitForQuery();

      expect(mockQueryHandler).not.toHaveBeenCalledWith({
        id: 'gid://gitlab/User/123',
        search: 'a',
        fullPath: 'a',
        hasSearch: true,
      });
    });
  });

  describe('groups and projects', () => {
    it('passes the groups and projects found to the namespace selector', async () => {
      await waitForQuery();

      expect(findSelector().props('groups')).toEqual(mockGroups);
      expect(findSelector().props('projects')).toEqual(mockProjects);
    });
  });

  describe('namespaces found by full path', () => {
    describe('when the full path matches a project', () => {
      beforeEach(async () => {
        createComponent({
          queryHandler: jest.fn().mockResolvedValue(mockFullPathProjectQueryResponse),
        });

        await search(mockNonMemberProject.fullPath);
        await waitForQuery();
      });

      it('offers a project the membership-scoped search did not return', () => {
        expect(findSelector().props('groups')).toEqual([]);
        expect(findSelector().props('projects')).toEqual([mockNonMemberProject]);
      });
    });

    describe('when the full path matches a group', () => {
      beforeEach(async () => {
        createComponent({
          queryHandler: jest.fn().mockResolvedValue(mockFullPathGroupQueryResponse),
        });

        await search(mockNonMemberGroup.fullPath);
        await waitForQuery();
      });

      it('offers a group the membership-scoped search did not return', () => {
        expect(findSelector().props('groups')).toEqual([mockNonMemberGroup]);
        expect(findSelector().props('projects')).toEqual([]);
      });
    });

    describe('when the full path matches a namespace the search also returned', () => {
      beforeEach(async () => {
        createComponent({
          queryHandler: jest.fn().mockResolvedValue({
            data: {
              ...mockSearchGroupsAndProjectsQueryResponse.data,
              projectByFullPath: mockProjects[1],
              groupByFullPath: mockGroups[1],
            },
          }),
        });

        await search(mockProjects[1].fullPath);
        await waitForQuery();
      });

      it('lists the matched project first without duplicating it', () => {
        expect(findSelector().props('projects')).toEqual([mockProjects[1], mockProjects[0]]);
      });

      it('lists the matched group first without duplicating it', () => {
        expect(findSelector().props('groups')).toEqual([mockGroups[1], mockGroups[0]]);
      });
    });
  });

  describe('events', () => {
    it('re-emits `input` from the namespace selector', () => {
      findSelector().vm.$emit('input', [mockProjects[0]]);

      expect(wrapper.emitted('input')).toEqual([[[mockProjects[0]]]]);
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
