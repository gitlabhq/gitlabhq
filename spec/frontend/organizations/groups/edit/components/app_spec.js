import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import App from '~/organizations/groups/edit/components/app.vue';
import {
  VISIBILITY_LEVEL_INTERNAL_INTEGER,
  VISIBILITY_LEVEL_PRIVATE_INTEGER,
  VISIBILITY_LEVEL_PUBLIC_INTEGER,
} from '~/visibility_level/constants';
import NewEditForm from '~/groups/components/new_edit_form.vue';

describe('OrganizationGroupsEditApp', () => {
  let wrapper;

  const defaultProvide = {
    group: {
      id: 1,
      fullName: 'Mock namespace / Foo bar',
      name: 'Foo bar',
      path: 'foo-bar',
    },
    basePath: 'https://gitlab.com',
    groupsAndProjectsOrganizationPath: '/-/organizations/carrot/groups_and_projects?display=groups',
    groupsOrganizationPath: '/-/organizations/default/groups',
    availableVisibilityLevels: [
      VISIBILITY_LEVEL_PRIVATE_INTEGER,
      VISIBILITY_LEVEL_INTERNAL_INTEGER,
      VISIBILITY_LEVEL_PUBLIC_INTEGER,
    ],
    restrictedVisibilityLevels: [],
    defaultVisibilityLevel: VISIBILITY_LEVEL_INTERNAL_INTEGER,
    pathMaxlength: 10,
    pathPattern: 'mockPattern',
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(App, {
      provide: defaultProvide,
      stubs: {
        GlSprintf,
      },
    });
  };

  const findForm = () => wrapper.findComponent(NewEditForm);

  it('renders page title', () => {
    createComponent();

    expect(
      wrapper.findByRole('heading', { name: 'Edit group: Mock namespace / Foo bar' }).exists(),
    ).toBe(true);
  });

  it('renders form and passes correct props', () => {
    createComponent();

    expect(findForm().props()).toEqual({
      loading: false,
      basePath: defaultProvide.basePath,
      cancelPath: defaultProvide.groupsAndProjectsOrganizationPath,
      pathMaxlength: defaultProvide.pathMaxlength,
      pathPattern: defaultProvide.pathPattern,
      availableVisibilityLevels: defaultProvide.availableVisibilityLevels,
      restrictedVisibilityLevels: defaultProvide.restrictedVisibilityLevels,
      initialFormValues: defaultProvide.group,
      submitButtonText: 'Save changes',
    });
  });
});
