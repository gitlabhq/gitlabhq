import { nextTick } from 'vue';
import { GlSprintf, GlLink } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import createGroupResponse from 'test_fixtures/controller/organizations/groups/post.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import App from '~/organizations/groups/new/components/app.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import NewEditForm from '~/groups/components/new_edit_form.vue';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import {
  VISIBILITY_LEVEL_PRIVATE_INTEGER,
  VISIBILITY_LEVEL_INTERNAL_INTEGER,
  VISIBILITY_LEVEL_PUBLIC_INTEGER,
  VISIBILITY_LEVEL_PUBLIC_STRING,
} from '~/visibility_level/constants';
import { HTTP_STATUS_OK, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/alert');

describe('OrganizationGroupsNewApp', () => {
  let wrapper;
  let axiosMock;

  const defaultProvide = {
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
        GlLink,
      },
    });
  };

  const findAllParagraphs = () => wrapper.findAll('p');
  const findAllLinks = () => wrapper.findAllComponents(GlLink);
  const findForm = () => wrapper.findComponent(NewEditForm);

  const submitForm = async () => {
    findForm().vm.$emit('submit', {
      name: 'Foo bar',
      path: 'foo-bar',
      visibilityLevel: VISIBILITY_LEVEL_PUBLIC_INTEGER,
    });
    await nextTick();
  };

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

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
      submitButtonText: 'Create group',
    });
  });

  describe('when form is submitted', () => {
    describe('when API is loading', () => {
      beforeEach(async () => {
        axiosMock
          .onPost(defaultProvide.groupsOrganizationPath)
          .reply(HTTP_STATUS_OK, createGroupResponse);
        createComponent();

        await submitForm();
      });

      it('sets `NewEditForm` `loading` prop to `true`', async () => {
        expect(findForm().props('loading')).toBe(true);
        await waitForPromises();
      });
    });

    describe('when API request is successful', () => {
      beforeEach(async () => {
        axiosMock
          .onPost(defaultProvide.groupsOrganizationPath)
          .reply(HTTP_STATUS_OK, createGroupResponse);
        createComponent();
        await submitForm();
        await waitForPromises();
      });

      it('calls API correct variables and redirects user to group web url with alert', () => {
        expect(JSON.parse(axiosMock.history.post[0].data)).toEqual({
          group: {
            name: 'Foo bar',
            path: 'foo-bar',
            visibility_level: VISIBILITY_LEVEL_PUBLIC_STRING,
          },
        });
        expect(visitUrlWithAlerts).toHaveBeenCalledWith(createGroupResponse.web_url, [
          {
            id: 'organization-group-successfully-created',
            message: `Group ${createGroupResponse.full_name} was successfully created.`,
            variant: 'info',
          },
        ]);
      });
    });

    describe('when API request is not successful', () => {
      beforeEach(async () => {
        axiosMock
          .onPost(defaultProvide.groupsOrganizationPath)
          .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        createComponent();
        await submitForm();
        await waitForPromises();
      });

      it('displays error alert and sets `loading` prop to `false`', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred creating a group in this organization. Please try again.',
          error: new Error('Request failed with status code 500'),
          captureError: true,
        });
        expect(findForm().props('loading')).toBe(false);
      });
    });
  });
});
