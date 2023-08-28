import { GlCollapsibleListbox, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupsAndProjects from '~/organizations/show/components/groups_and_projects.vue';
import { createRouter } from '~/organizations/show';

describe('OrganizationShowGroupsAndProjects', () => {
  const router = createRouter();
  const routerMock = {
    push: jest.fn(),
  };
  const defaultPropsData = {
    groupsAndProjectsOrganizationPath: '/-/organizations/default/groups_and_projects',
  };

  let wrapper;

  const createComponent = ({ routeQuery = {} } = {}) => {
    wrapper = shallowMountExtended(GroupsAndProjects, {
      router,
      mocks: { $route: { path: '/', query: routeQuery }, $router: routerMock },
      propsData: defaultPropsData,
    });
  };

  const findCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  it('renders listbox with expected props', () => {
    createComponent();

    expect(findCollapsibleListbox().props()).toMatchObject({
      items: [
        {
          value: 'frequently_visited_projects',
          text: 'Frequently visited projects',
        },
        {
          value: 'frequently_visited_groups',
          text: 'Frequently visited groups',
        },
      ],
      selected: 'frequently_visited_projects',
    });
  });

  describe.each`
    displayQueryParam                | expectedHref
    ${'frequently_visited_projects'} | ${`${defaultPropsData.groupsAndProjectsOrganizationPath}?display=projects`}
    ${'frequently_visited_groups'}   | ${`${defaultPropsData.groupsAndProjectsOrganizationPath}?display=groups`}
  `('when display query param is $displayQueryParam', ({ displayQueryParam, expectedHref }) => {
    beforeEach(() => {
      createComponent({ routeQuery: { display: displayQueryParam } });
    });

    it('sets listbox `selected` prop correctly', () => {
      expect(findCollapsibleListbox().props('selected')).toBe(displayQueryParam);
    });

    it('renders "View all" link with correct href', () => {
      expect(wrapper.findComponent(GlLink).attributes('href')).toBe(expectedHref);
    });
  });

  it('renders label and associates listbox with it', () => {
    createComponent();

    const expectedId = 'display-listbox-label';

    expect(wrapper.findByTestId('label').attributes('id')).toBe(expectedId);
    expect(findCollapsibleListbox().props('toggleAriaLabelledBy')).toBe(expectedId);
  });

  describe('when listbox item is selected', () => {
    const selectValue = 'frequently_visited_groups';

    beforeEach(() => {
      createComponent();

      findCollapsibleListbox().vm.$emit('select', selectValue);
    });

    it('updates `display` query param', () => {
      expect(routerMock.push).toHaveBeenCalledWith({
        query: { display: selectValue },
      });
    });
  });
});
