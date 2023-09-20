import { GlCollapsibleListbox, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupsAndProjects from '~/organizations/show/components/groups_and_projects.vue';
import { createRouter } from '~/organizations/show';
import GroupsView from '~/organizations/shared/components/groups_view.vue';
import ProjectsView from '~/organizations/shared/components/projects_view.vue';

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
    displayQueryParam                | expectedViewAllLinkQuery | expectedViewComponent | expectedDisplayListboxSelectedProp
    ${'frequently_visited_projects'} | ${'?display=projects'}   | ${ProjectsView}       | ${'frequently_visited_projects'}
    ${'frequently_visited_groups'}   | ${'?display=groups'}     | ${GroupsView}         | ${'frequently_visited_groups'}
    ${'unsupported'}                 | ${'?display=projects'}   | ${ProjectsView}       | ${'frequently_visited_projects'}
  `(
    'when display query param is $displayQueryParam',
    ({
      displayQueryParam,
      expectedViewAllLinkQuery,
      expectedViewComponent,
      expectedDisplayListboxSelectedProp,
    }) => {
      beforeEach(() => {
        createComponent({ routeQuery: { display: displayQueryParam } });
      });

      it('sets listbox `selected` prop correctly', () => {
        expect(findCollapsibleListbox().props('selected')).toBe(expectedDisplayListboxSelectedProp);
      });

      it('renders "View all" link with correct href', () => {
        expect(wrapper.findComponent(GlLink).attributes('href')).toBe(
          `${defaultPropsData.groupsAndProjectsOrganizationPath}${expectedViewAllLinkQuery}`,
        );
      });

      it('renders expected view', () => {
        expect(
          wrapper.findComponent(expectedViewComponent).props('shouldShowEmptyStateButtons'),
        ).toBe(true);
      });
    },
  );

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
