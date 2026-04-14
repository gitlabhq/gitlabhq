import { GlCollapsibleListbox, GlButtonGroup, GlButton } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import NewResourceDropdown from '~/vue_shared/components/new_resource_dropdown/new_resource_dropdown.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import searchUserProjectsWithIssuesEnabledQuery from '~/vue_shared/components/new_resource_dropdown/graphql/search_user_projects_with_issues_enabled.query.graphql';
import { RESOURCE_TYPES } from '~/vue_shared/components/new_resource_dropdown/constants';
import searchProjectsWithinGroupQuery from '~/work_items/list/graphql/search_projects.query.graphql';
import { DASH_SCOPE, joinPaths } from '~/lib/utils/url_utility';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import {
  emptySearchProjectsQueryResponse,
  emptySearchProjectsWithinGroupQueryResponse,
  project1,
  project2,
  project3,
  searchProjectsQueryResponse,
  searchProjectsWithinGroupQueryResponse,
} from './mock_data';

jest.mock('~/alert');

describe('NewResourceDropdown component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const withinGroupProps = {
    query: searchProjectsWithinGroupQuery,
    queryVariables: { fullPath: 'mushroom-kingdom' },
    extractProjects: (data) => data.group.projects.nodes,
  };

  const mountComponent = ({
    query = searchUserProjectsWithIssuesEnabledQuery,
    queryResponse = searchProjectsQueryResponse,
    mountFn = shallowMount,
    propsData = {},
    stubs = {},
  } = {}) => {
    const requestHandlers = [[query, jest.fn().mockResolvedValue(queryResponse)]];
    const apolloProvider = createMockApollo(requestHandlers);

    wrapper = mountFn(NewResourceDropdown, {
      apolloProvider,
      propsData,
      stubs: {
        ...stubs,
      },
    });
  };

  const findButtonGroup = () => wrapper.findComponent(GlButtonGroup);
  const findMainButton = () => wrapper.findComponent(GlButton);
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);

  const showDropdown = async () => {
    findListbox().vm.$emit('shown');
    await waitForPromises();
    jest.advanceTimersByTime(DEBOUNCE_DELAY);
    await waitForPromises();
  };

  afterEach(() => {
    localStorage.clear();
  });

  it('renders a button group with main button and dropdown', () => {
    mountComponent();
    expect(findButtonGroup().exists()).toBe(true);
    expect(findMainButton().exists()).toBe(true);
    expect(findListbox().exists()).toBe(true);
  });

  it('renders a label for the main button', () => {
    mountComponent();
    expect(findMainButton().text()).toBe('Select project to create issue');
  });

  describe.each`
    description         | propsData           | query                                       | queryResponse                             | emptyResponse
    ${'by default'}     | ${undefined}        | ${searchUserProjectsWithIssuesEnabledQuery} | ${searchProjectsQueryResponse}            | ${emptySearchProjectsQueryResponse}
    ${'within a group'} | ${withinGroupProps} | ${searchProjectsWithinGroupQuery}           | ${searchProjectsWithinGroupQueryResponse} | ${emptySearchProjectsWithinGroupQueryResponse}
  `('$description', ({ propsData, query, queryResponse, emptyResponse }) => {
    it('renders project options', async () => {
      mountComponent({ mountFn: mount, query, queryResponse, propsData });
      await showDropdown();

      const items = findListbox().props('items');
      expect(items).toHaveLength(3);
      expect(items[0].text).toBe(project1.nameWithNamespace);
      expect(items[1].text).toBe(project2.nameWithNamespace);
      expect(items[2].text).toBe(project3.nameWithNamespace);
    });

    it('renders "No matches found" when there are no matches', async () => {
      mountComponent({
        query,
        queryResponse: emptyResponse,
        mountFn: mount,
        propsData,
      });

      await showDropdown();

      expect(findListbox().props('noResultsText')).toBe(NewResourceDropdown.i18n.noMatchesFound);
      expect(findListbox().props('items')).toHaveLength(0);
    });

    describe.each`
      resourceType       | expectedDefaultLabel                        | expectedPath            | expectedLabel
      ${'issue'}         | ${'Select project to create issue'}         | ${'issues/new'}         | ${'New issue in'}
      ${'merge-request'} | ${'Select project to create merge request'} | ${'merge_requests/new'} | ${'New merge request in'}
      ${'milestone'}     | ${'Select project to create milestone'}     | ${'milestones/new'}     | ${'New milestone in'}
    `(
      'with resource type $resourceType',
      ({ resourceType, expectedDefaultLabel, expectedPath, expectedLabel }) => {
        describe('when no project is selected', () => {
          beforeEach(() => {
            mountComponent({
              query,
              queryResponse,
              propsData: { ...propsData, resourceType },
              mountFn: mount,
            });
          });

          it('main button is not a link', () => {
            expect(findMainButton().props('href')).toBeUndefined();
          });

          it('displays default text on the main button', () => {
            expect(findMainButton().text()).toBe(expectedDefaultLabel);
          });

          describe('when main button is clicked', () => {
            it('opens dropdown', async () => {
              await findMainButton().trigger('click');

              expect(findListbox().emitted('shown')).toEqual([[]]);
            });
          });
        });

        describe('when a project is selected', () => {
          beforeEach(async () => {
            mountComponent({
              mountFn: mount,
              query,
              queryResponse,
              propsData: { ...propsData, resourceType },
            });
            await showDropdown();

            // Simulate user selecting a project
            const listboxItems = findListbox().props('items');
            findListbox().vm.$emit('select', listboxItems[0].value);
            await nextTick();
          });

          it('main button is a link', () => {
            const href = joinPaths(project1.webUrl, DASH_SCOPE, expectedPath);
            expect(findMainButton().props('href')).toBe(href);
          });

          it('displays project name on the main button', () => {
            expect(findMainButton().text()).toBe(`${expectedLabel} ${project1.name}`);
          });
        });
      },
    );
  });

  describe('local storage sync', () => {
    it('retrieves the selected project from localStorage', async () => {
      mountComponent();
      expect(findMainButton().props('href')).toBeUndefined();

      findLocalStorageSync().vm.$emit('input', {
        webUrl: project1.webUrl,
        name: project1.name,
      });
      await nextTick();

      expect(findMainButton().props('href')).toBe(
        joinPaths(project1.webUrl, DASH_SCOPE, 'issues/new'),
      );
      expect(findMainButton().text()).toBe(`New issue in ${project1.name}`);
    });

    it('retrieves legacy cache from localStorage', async () => {
      mountComponent();

      expect(findMainButton().props('href')).toBeUndefined();

      findLocalStorageSync().vm.$emit('input', {
        url: `${project1.webUrl}/issues/new`,
        name: project1.name,
      });
      await nextTick();

      expect(findMainButton().props('href')).toBe(
        joinPaths(project1.webUrl, DASH_SCOPE, 'issues/new'),
      );
      expect(findMainButton().text()).toBe(`New issue in ${project1.name}`);
    });

    describe.each(RESOURCE_TYPES)('with resource type %s', (resourceType) => {
      it('computes the local storage key without a group', () => {
        mountComponent({
          propsData: { resourceType },
        });

        expect(findLocalStorageSync().props('storageKey')).toBe(
          `group--new-${resourceType}-recent-project`,
        );
      });

      it('computes the local storage key with a group', () => {
        const groupId = '22';
        mountComponent({
          propsData: { groupId, resourceType },
        });

        expect(findLocalStorageSync().props('storageKey')).toBe(
          `group-${groupId}-new-${resourceType}-recent-project`,
        );
      });
    });
  });
});
