import { GlDropdown, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import NewIssueDropdown from '~/vue_shared/components/new_issue_dropdown/new_issue_dropdown.vue';
import searchUserProjectsQuery from '~/vue_shared/components/new_issue_dropdown/graphql/search_user_projects.query.graphql';
import searchProjectsWithinGroupQuery from '~/issues/list/queries/search_projects.query.graphql';
import { DASH_SCOPE, joinPaths } from '~/lib/utils/url_utility';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import {
  emptySearchProjectsQueryResponse,
  emptySearchProjectsWithinGroupQueryResponse,
  project1,
  project3,
  searchProjectsQueryResponse,
  searchProjectsWithinGroupQueryResponse,
} from './mock_data';

describe('NewIssueDropdown component', () => {
  let wrapper;

  Vue.use(VueApollo);

  // Props
  const withinGroupProps = {
    query: searchProjectsWithinGroupQuery,
    queryVariables: { fullPath: 'mushroom-kingdom' },
    extractProjects: (data) => data.group.projects.nodes,
  };

  const mountComponent = ({
    search = '',
    query = searchUserProjectsQuery,
    queryResponse = searchProjectsQueryResponse,
    mountFn = shallowMount,
    propsData = {},
  } = {}) => {
    const requestHandlers = [[query, jest.fn().mockResolvedValue(queryResponse)]];
    const apolloProvider = createMockApollo(requestHandlers);

    return mountFn(NewIssueDropdown, {
      apolloProvider,
      propsData,
      data() {
        return { search };
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findInput = () => wrapper.findComponent(GlSearchBoxByType);
  const showDropdown = async () => {
    findDropdown().vm.$emit('shown');
    await waitForPromises();
    jest.advanceTimersByTime(DEBOUNCE_DELAY);
    await waitForPromises();
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders a split dropdown', () => {
    wrapper = mountComponent();

    expect(findDropdown().props('split')).toBe(true);
  });

  it('renders a label for the dropdown toggle button', () => {
    wrapper = mountComponent();

    expect(findDropdown().attributes('toggle-text')).toBe(NewIssueDropdown.i18n.toggleButtonLabel);
  });

  it('focuses on input when dropdown is shown', async () => {
    wrapper = mountComponent({ mountFn: mount });

    const inputSpy = jest.spyOn(findInput().vm, 'focusInput');

    await showDropdown();

    expect(inputSpy).toHaveBeenCalledTimes(1);
  });

  describe.each`
    description         | propsData           | query                             | queryResponse                             | emptyResponse
    ${'by default'}     | ${undefined}        | ${searchUserProjectsQuery}        | ${searchProjectsQueryResponse}            | ${emptySearchProjectsQueryResponse}
    ${'within a group'} | ${withinGroupProps} | ${searchProjectsWithinGroupQuery} | ${searchProjectsWithinGroupQueryResponse} | ${emptySearchProjectsWithinGroupQueryResponse}
  `('$description', ({ propsData, query, queryResponse, emptyResponse }) => {
    it('renders projects with issues enabled', async () => {
      wrapper = mountComponent({ mountFn: mount, query, queryResponse, propsData });
      await showDropdown();

      const listItems = wrapper.findAll('li');

      expect(listItems.at(0).text()).toBe(project1.nameWithNamespace);
      expect(listItems.at(1).text()).toBe(project3.nameWithNamespace);
    });

    it('renders `No matches found` when there are no matches', async () => {
      wrapper = mountComponent({
        search: 'no matches',
        query,
        queryResponse: emptyResponse,
        mountFn: mount,
        propsData,
      });

      await showDropdown();

      expect(wrapper.find('li').text()).toBe(NewIssueDropdown.i18n.noMatchesFound);
    });

    describe('when no project is selected', () => {
      beforeEach(() => {
        wrapper = mountComponent({ query, queryResponse, propsData });
      });

      it('dropdown button is not a link', () => {
        expect(findDropdown().attributes('split-href')).toBeUndefined();
      });

      it('displays default text on the dropdown button', () => {
        expect(findDropdown().props('text')).toBe(NewIssueDropdown.i18n.defaultDropdownText);
      });
    });

    describe('when a project is selected', () => {
      beforeEach(async () => {
        wrapper = mountComponent({ mountFn: mount, query, queryResponse, propsData });
        await showDropdown();

        wrapper.findComponent(GlDropdownItem).vm.$emit('click', project1);
      });

      it('dropdown button is a link', () => {
        const href = joinPaths(project1.webUrl, DASH_SCOPE, 'issues/new');

        expect(findDropdown().attributes('split-href')).toBe(href);
      });

      it('displays project name on the dropdown button', () => {
        expect(findDropdown().props('text')).toBe(`New issue in ${project1.name}`);
      });
    });
  });
});
