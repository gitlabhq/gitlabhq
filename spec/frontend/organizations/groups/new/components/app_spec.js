import { GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import App from '~/organizations/groups/new/components/app.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import NewGroupForm from '~/groups/components/new_group_form.vue';

describe('OrganizationGroupsNewApp', () => {
  let wrapper;

  const defaultProvide = {
    organizationId: 1,
    basePath: 'https://gitlab.com',
    groupsOrganizationPath: '/-/organizations/carrot/groups_and_projects?display=groups',
    mattermostEnabled: false,
    availableVisibilityLevels: [0, 10, 20],
    restrictedVisibilityLevels: [],
    pathMaxlength: 10,
    pathPattern: 'mockPattern',
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(App, {
      provide: defaultProvide,
      stubs: {
        GlSprintf,
        GlLink,
      },
    });
  };

  const findAllParagraphs = () => wrapper.findAll('p');
  const findAllLinks = () => wrapper.findAllComponents(GlLink);

  it('renders page title and description', () => {
    createComponent();

    expect(wrapper.findByRole('heading', { name: 'New group' }).exists()).toBe(true);

    expect(findAllParagraphs().at(0).text()).toMatchInterpolatedText(
      'Groups allow you to manage and collaborate across multiple projects. Members of a group have access to all of its projects.',
    );
    expect(findAllLinks().at(0).attributes('href')).toBe(helpPagePath('user/group/index'));
    expect(findAllParagraphs().at(1).text()).toContain(
      'Groups can also be nested by creating subgroups.',
    );
    expect(findAllLinks().at(1).attributes('href')).toBe(
      helpPagePath('user/group/subgroups/index'),
    );
  });

  it('renders form and passes correct props', () => {
    createComponent();

    expect(wrapper.findComponent(NewGroupForm).props()).toEqual({
      basePath: 'https://gitlab.com',
      cancelPath: '/-/organizations/carrot/groups_and_projects?display=groups',
      pathMaxlength: 10,
      pathPattern: 'mockPattern',
      availableVisibilityLevels: defaultProvide.availableVisibilityLevels,
      restrictedVisibilityLevels: defaultProvide.restrictedVisibilityLevels,
    });
  });
});
