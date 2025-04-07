import { GlDropdown, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import NewResourceDropdown from '~/vue_shared/components/new_resource_dropdown/new_resource_dropdown.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import searchUserProjectsWithIssuesEnabledQuery from '~/vue_shared/components/new_resource_dropdown/graphql/search_user_projects_with_issues_enabled.query.graphql';
import { RESOURCE_TYPES } from '~/vue_shared/components/new_resource_dropdown/constants';
import searchProjectsWithinGroupQuery from '~/issues/list/queries/search_projects.query.graphql';
import { DASH_SCOPE, joinPaths } from '~/lib/utils/url_utility';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import { stubComponent } from 'helpers/stub_component';
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

  // Props
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

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findGlDropdownItem = () => wrapper.findComponent(GlDropdownItem);
  const findInput = () => wrapper.findComponent(GlSearchBoxByType);
  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);
  const showDropdown = async () => {
    findDropdown().vm.$emit('shown');
    await waitForPromises();
    jest.advanceTimersByTime(DEBOUNCE_DELAY);
    await waitForPromises();
  };

  afterEach(() => {
    localStorage.clear();
  });

  it('renders a split dropdown', () => {
    mountComponent();

    expect(findDropdown().props('split')).toBe(true);
  });

  it('renders a label for the dropdown toggle button', () => {
    mountComponent();

    expect(findDropdown().attributes('toggle-text')).toBe(
      NewResourceDropdown.i18n.toggleButtonLabel,
    );
  });

  it('focuses on input when dropdown is shown', async () => {
    const inputMock = jest.fn();
    mountComponent({
      stubs: {
        GlSearchBoxByType: stubComponent(GlSearchBoxByType, {
          methods: { focusInput: inputMock },
        }),
      },
    });

    await showDropdown();

    expect(inputMock).toHaveBeenCalledTimes(1);
  });

  describe.each`
    description         | propsData           | query                                       | queryResponse                             | emptyResponse
    ${'by default'}     | ${undefined}        | ${searchUserProjectsWithIssuesEnabledQuery} | ${searchProjectsQueryResponse}            | ${emptySearchProjectsQueryResponse}
    ${'within a group'} | ${withinGroupProps} | ${searchProjectsWithinGroupQuery}           | ${searchProjectsWithinGroupQueryResponse} | ${emptySearchProjectsWithinGroupQueryResponse}
  `('$description', ({ propsData, query, queryResponse, emptyResponse }) => {
    it('renders projects options', async () => {
      mountComponent({ mountFn: mount, query, queryResponse, propsData });
      await showDropdown();

      const listItems = wrapper.findAll('li');

      expect(listItems.at(0).text()).toBe(project1.nameWithNamespace);
      expect(listItems.at(1).text()).toBe(project2.nameWithNamespace);
      expect(listItems.at(2).text()).toBe(project3.nameWithNamespace);
    });

    it('renders `No matches found` when there are no matches', async () => {
      mountComponent({
        query,
        queryResponse: emptyResponse,
        mountFn: mount,
        propsData,
      });

      await findInput().vm.$emit('input', 'no matches');
      await showDropdown();

      expect(wrapper.find('li').text()).toBe(NewResourceDropdown.i18n.noMatchesFound);
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
            });
          });

          it('dropdown button is not a link', () => {
            expect(findDropdown().props('splitHref')).toBe('');
          });

          it('displays default text on the dropdown button', () => {
            expect(findDropdown().props('text')).toBe(expectedDefaultLabel);
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

            findGlDropdownItem().vm.$emit('click', project1);
          });

          it('dropdown button is a link', () => {
            const href = joinPaths(project1.webUrl, DASH_SCOPE, expectedPath);

            expect(findDropdown().props('splitHref')).toBe(href);
          });

          it('displays project name on the dropdown button', () => {
            expect(findDropdown().props('text')).toBe(`${expectedLabel} ${project1.name}`);
          });
        });
      },
    );
  });

  describe('local storage sync', () => {
    it('retrieves the selected project from the localStorage', async () => {
      mountComponent();
      const dropdown = findDropdown();

      expect(dropdown.props('splitHref')).toBe('');

      findLocalStorageSync().vm.$emit('input', {
        webUrl: project1.webUrl,
        name: project1.name,
      });
      await nextTick();

      expect(dropdown.props('splitHref')).toBe(
        joinPaths(project1.webUrl, DASH_SCOPE, 'issues/new'),
      );
      expect(dropdown.props('text')).toBe(`New issue in ${project1.name}`);
    });

    it('retrieves legacy cache from the localStorage', async () => {
      mountComponent();
      const dropdown = findDropdown();

      expect(dropdown.props('splitHref')).toBe('');

      findLocalStorageSync().vm.$emit('input', {
        url: `${project1.webUrl}/issues/new`,
        name: project1.name,
      });

      await nextTick();

      expect(dropdown.props('splitHref')).toBe(
        joinPaths(project1.webUrl, DASH_SCOPE, 'issues/new'),
      );
      expect(dropdown.props('text')).toBe(`New issue in ${project1.name}`);
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
