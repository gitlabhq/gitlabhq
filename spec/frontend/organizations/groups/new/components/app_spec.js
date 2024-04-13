import { nextTick } from 'vue';
import { GlSprintf, GlLink } from '@gitlab/ui';
import group from 'test_fixtures/api/groups/post.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import App from '~/organizations/groups/new/components/app.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import NewGroupForm from '~/groups/components/new_group_form.vue';
import { createGroup } from '~/api/groups_api';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import {
  VISIBILITY_LEVEL_PRIVATE_INTEGER,
  VISIBILITY_LEVEL_INTERNAL_INTEGER,
  VISIBILITY_LEVEL_PUBLIC_INTEGER,
  VISIBILITY_LEVEL_PUBLIC_STRING,
} from '~/visibility_level/constants';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/api/groups_api');
jest.mock('~/lib/utils/url_utility');
jest.mock('~/alert');

describe('OrganizationGroupsNewApp', () => {
  let wrapper;

  const defaultProvide = {
    organizationId: 1,
    basePath: 'https://gitlab.com',
    groupsOrganizationPath: '/-/organizations/carrot/groups_and_projects?display=groups',
    mattermostEnabled: false,
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
        GlLink,
      },
    });
  };

  const findAllParagraphs = () => wrapper.findAll('p');
  const findAllLinks = () => wrapper.findAllComponents(GlLink);
  const findForm = () => wrapper.findComponent(NewGroupForm);

  const submitForm = async () => {
    findForm().vm.$emit('submit', {
      name: 'Foo bar',
      path: 'foo-bar',
      visibilityLevel: VISIBILITY_LEVEL_PUBLIC_INTEGER,
    });
    await nextTick();
  };

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

    expect(findForm().props()).toEqual({
      loading: false,
      basePath: 'https://gitlab.com',
      cancelPath: '/-/organizations/carrot/groups_and_projects?display=groups',
      pathMaxlength: 10,
      pathPattern: 'mockPattern',
      availableVisibilityLevels: defaultProvide.availableVisibilityLevels,
      restrictedVisibilityLevels: defaultProvide.restrictedVisibilityLevels,
      initialFormValues: {
        name: '',
        path: '',
        visibilityLevel: VISIBILITY_LEVEL_INTERNAL_INTEGER,
      },
    });
  });

  describe('when form is submitted', () => {
    describe('when API is loading', () => {
      beforeEach(async () => {
        createGroup.mockResolvedValueOnce({ data: group });
        createComponent();

        await submitForm();
      });

      it('sets `NewGroupForm` `loading` prop to `true`', async () => {
        expect(findForm().props('loading')).toBe(true);
        await waitForPromises();
      });
    });

    describe('when API request is successful', () => {
      beforeEach(async () => {
        createGroup.mockResolvedValueOnce({ data: group });
        createComponent();
        await submitForm();
        await waitForPromises();
      });

      it('calls API correct variables and redirects user to group web url with alert', () => {
        expect(createGroup).toHaveBeenCalledWith({
          organization_id: defaultProvide.organizationId,
          name: 'Foo bar',
          path: 'foo-bar',
          visibility: VISIBILITY_LEVEL_PUBLIC_STRING,
        });
        expect(visitUrlWithAlerts).toHaveBeenCalledWith(group.web_url, [
          {
            id: 'organization-group-successfully-created',
            message: `Group ${group.full_name} was successfully created.`,
            variant: 'info',
          },
        ]);
      });
    });

    describe('when API request is not successful', () => {
      const error = new Error();

      beforeEach(async () => {
        createGroup.mockRejectedValueOnce(error);
        createComponent();
        await submitForm();
        await waitForPromises();
      });

      it('displays error alert and sets `loading` prop to `false`', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred creating a group in this organization. Please try again.',
          error,
          captureError: true,
        });
        expect(findForm().props('loading')).toBe(false);
      });
    });
  });
});
