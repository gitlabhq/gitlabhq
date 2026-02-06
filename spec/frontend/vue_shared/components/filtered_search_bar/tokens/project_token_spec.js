import { GlFilteredSearchTokenSegment } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';

import projectAutocompleteQuery from '~/graphql_shared/queries/projects_autocomplete.query.graphql';
import projectToken from '~/vue_shared/components/filtered_search_bar/tokens/project_token.vue';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';

import { mockProjectToken, mockProjects, mockProjectResponse } from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

const projectsQueryHandler = jest.fn().mockResolvedValue(mockProjectResponse);
const mockApollo = createMockApollo([[projectAutocompleteQuery, projectsQueryHandler]]);

describe('ProjectToken', () => {
  let wrapper;

  const createComponent = (options = {}) => {
    const {
      config = mockProjectToken,
      value = { data: '' },
      active = false,
      stubs,
      data = {},
      listeners = {},
      apollo = mockApollo,
      mountFn = shallowMount,
    } = options;

    wrapper = mountFn(projectToken, {
      apolloProvider: apollo,
      propsData: {
        config,
        value,
        active,
        cursorPosition: 'start',
      },
      provide: {
        portalName: 'fake target',
        alignSuggestions: jest.fn(),
        suggestionsListClass: () => 'custom-class',
        termsAsTokens: () => false,
      },
      data() {
        return { ...data };
      },
      stubs: {
        ...stubs,
      },
      listeners,
    });
  };

  const findBaseToken = () => wrapper.findComponent(BaseToken);

  describe('methods', () => {
    describe('fetchProjectsBySearchTerm', () => {
      const triggerFetchProjects = (searchTerm = null) => {
        findBaseToken().vm.$emit('fetch-suggestions', searchTerm);
        return waitForPromises();
      };

      beforeEach(() => {
        createComponent({});
      });

      it('sets loading state', () => {
        expect(findBaseToken().props('suggestionsLoading')).toBe(true);
      });

      describe('when request is successful', () => {
        const searchTerm = 'coverage';

        beforeEach(async () => {
          createComponent({});
          triggerFetchProjects(searchTerm);
          await waitForPromises();
        });

        it('calls `fetchProjects` with provided searchTerm param', () => {
          expect(projectsQueryHandler).toHaveBeenCalledWith({ search: searchTerm });
        });

        it('sets response to `projects` when request is successful', () => {
          expect(findBaseToken().props('suggestions')).toEqual(mockProjects);
        });

        it('sets `loading` to false when request completes', () => {
          expect(findBaseToken().props('suggestionsLoading')).toBe(false);
        });
      });

      describe('when request fails', () => {
        const apollo = createMockApollo([
          [projectAutocompleteQuery, jest.fn().mockRejectedValue()],
        ]);
        beforeEach(async () => {
          createComponent({ apollo });
          triggerFetchProjects();
          await waitForPromises();
        });

        it('calls `createAlert`', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: 'There was a problem fetching projects.',
          });
        });

        it('sets `loading` to false when request completes', () => {
          expect(findBaseToken().props('suggestionsLoading')).toBe(false);
        });
      });
    });
  });

  describe('template', () => {
    const activateSuggestionsList = () => {
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
    };

    it('renders base-token component', () => {
      createComponent({
        ...mockProjectToken,
        value: { data: 'gitlab-duo/test' },
        data: { projects: mockProjects },
        mountFn: mount,
      });

      activateSuggestionsList();
      const baseTokenEl = findBaseToken();

      expect(baseTokenEl.props()).toMatchObject({
        suggestions: [
          {
            fullPath: 'gitlab-duo/test',
          },
          {
            fullPath: 'root/coverage',
          },
        ],
        valueIdentifier: expect.any(Function),
        getActiveTokenValue: expect.any(Function),
      });
    });

    it('renders token item when value is selected', () => {
      createComponent({
        value: { data: 'gitlab-duo/test' },
        data: { projects: mockProjects },
        mountFn: mount,
      });

      activateSuggestionsList();
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);
      expect(tokenSegments).toHaveLength(3);
      const tokenValue = tokenSegments.at(2);
      expect(tokenValue.text()).toBe('gitlab-duo/test');
    });
  });
});
