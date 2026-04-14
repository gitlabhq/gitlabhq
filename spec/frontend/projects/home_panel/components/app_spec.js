import VueApollo from 'vue-apollo';
import Vue from 'vue';
import getProjectByPathResponse from 'test_fixtures/graphql/graphql_shared/queries/get_project_by_path.graphql.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import HomePanelApp from '~/projects/home_panel/components/app.vue';
import ProjectHeaderActions from '~/projects/home_panel/components/header_actions.vue';
import ForksButton from '~/forks/components/forks_button.vue';
import NotificationsDropdown from '~/notifications/components/notifications_dropdown.vue';
import StarCount from '~/stars/components/star_count.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import getProjectByPath from '~/graphql_shared/queries/get_project_by_path.graphql';
import { ACTION_COPY_ID } from '~/vue_shared/components/list_actions/constants';
import { formatProject } from '~/projects/home_panel/formatter';
import { createAlert } from '~/alert';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('HomePanelApp', () => {
  let wrapper;
  let getProjectByPathHandler;

  const mockProject = getProjectByPathResponse.data.project;

  const createComponent = ({
    isLoggedIn = false,
    provide = {},
    propsData = {},
    getProjectByPathHandler: handler = jest.fn(),
  } = {}) => {
    getProjectByPathHandler = handler;

    window.gon.current_user_id = isLoggedIn ? 1 : null;
    window.gon.relative_url_root = '';

    const apolloProvider = createMockApollo([[getProjectByPath, getProjectByPathHandler]]);

    wrapper = shallowMountExtended(HomePanelApp, {
      apolloProvider,
      provide: {
        projectId: mockProject.id,
        projectFullPath: 'foo',
        ...provide,
      },
      propsData: {
        canRequestAccess: false,
        canWithdrawAccessRequest: false,
        requestAccessPath: '',
        withdrawAccessRequestPath: '',
        dashboardPath: '/dashboard/projects',
        ...propsData,
      },
    });
  };

  const findAdminButton = () => wrapper.find('[data-testid="admin-button"]');
  const findForksButton = () => wrapper.findComponent(ForksButton);
  const findNotificationsDropdown = () => wrapper.findComponent(NotificationsDropdown);
  const findHeaderActions = () => wrapper.findComponent(ProjectHeaderActions);
  const findStarCount = () => wrapper.findComponent(StarCount);

  describe.each`
    isLoggedIn | canReadProject | isProjectEmpty | adminPath               | isForkButtonVisible | isNotificationDropdownVisible | isStarCountVisible | isAdminButtonVisible
    ${true}    | ${true}        | ${true}        | ${undefined}            | ${false}            | ${true}                       | ${true}            | ${false}
    ${true}    | ${true}        | ${true}        | ${null}                 | ${false}            | ${true}                       | ${true}            | ${false}
    ${true}    | ${true}        | ${true}        | ${''}                   | ${false}            | ${true}                       | ${true}            | ${false}
    ${true}    | ${true}        | ${false}       | ${''}                   | ${true}             | ${true}                       | ${true}            | ${false}
    ${true}    | ${false}       | ${true}        | ${''}                   | ${false}            | ${false}                      | ${true}            | ${false}
    ${true}    | ${false}       | ${false}       | ${''}                   | ${false}            | ${false}                      | ${true}            | ${false}
    ${true}    | ${true}        | ${true}        | ${'project/admin/path'} | ${false}            | ${true}                       | ${true}            | ${true}
    ${true}    | ${true}        | ${false}       | ${'project/admin/path'} | ${true}             | ${true}                       | ${true}            | ${true}
    ${true}    | ${false}       | ${true}        | ${'project/admin/path'} | ${false}            | ${false}                      | ${true}            | ${true}
    ${true}    | ${false}       | ${false}       | ${'project/admin/path'} | ${false}            | ${false}                      | ${true}            | ${true}
    ${false}   | ${true}        | ${true}        | ${''}                   | ${false}            | ${false}                      | ${true}            | ${false}
    ${false}   | ${true}        | ${false}       | ${''}                   | ${false}            | ${false}                      | ${true}            | ${false}
    ${false}   | ${false}       | ${true}        | ${''}                   | ${false}            | ${false}                      | ${true}            | ${false}
    ${false}   | ${false}       | ${false}       | ${''}                   | ${false}            | ${false}                      | ${true}            | ${false}
    ${false}   | ${true}        | ${true}        | ${'project/admin/path'} | ${false}            | ${false}                      | ${true}            | ${true}
    ${false}   | ${true}        | ${false}       | ${'project/admin/path'} | ${false}            | ${false}                      | ${true}            | ${true}
    ${false}   | ${false}       | ${true}        | ${'project/admin/path'} | ${false}            | ${false}                      | ${true}            | ${true}
    ${false}   | ${false}       | ${false}       | ${'project/admin/path'} | ${false}            | ${false}                      | ${true}            | ${true}
  `(
    'renders components',
    ({
      isLoggedIn,
      canReadProject,
      isProjectEmpty,
      adminPath,
      isForkButtonVisible,
      isNotificationDropdownVisible,
      isStarCountVisible,
      isAdminButtonVisible,
    }) => {
      it('as expected', () => {
        createComponent({
          isLoggedIn,
          provide: {
            adminPath,
            canReadProject,
            isProjectEmpty,
          },
        });

        expect(findForksButton().exists()).toBe(isForkButtonVisible);
        expect(findNotificationsDropdown().exists()).toBe(isNotificationDropdownVisible);
        expect(findStarCount().exists()).toBe(isStarCountVisible);
        expect(findAdminButton().exists()).toBe(isAdminButtonVisible);
      });
    },
  );

  describe('when user is not logged in', () => {
    beforeEach(async () => {
      createComponent({ isLoggedIn: false });
      await waitForPromises();
    });

    it('does not load project', () => {
      expect(getProjectByPathHandler).not.toHaveBeenCalled();
    });

    it('renders header actions with basic project data', () => {
      expect(findHeaderActions().props('project')).toEqual({
        id: mockProject.id,
        availableActions: [ACTION_COPY_ID],
      });
    });
  });

  describe('when user is logged in', () => {
    it('loads projects', () => {
      createComponent({ isLoggedIn: true });

      expect(getProjectByPathHandler).toHaveBeenCalledWith({ fullPath: 'foo' });
    });

    describe('when project is loaded', () => {
      beforeEach(async () => {
        createComponent({
          isLoggedIn: true,
          getProjectByPathHandler: jest.fn().mockResolvedValue(getProjectByPathResponse),
          propsData: {
            canRequestAccess: true,
            canWithdrawAccessRequest: false,
            requestAccessPath: '/path/to/request',
            withdrawAccessRequestPath: '/path/to/withdraw',
          },
        });

        await waitForPromises();
      });

      it('renders header actions with formatted project', () => {
        const formattedProject = formatProject(mockProject, {
          canRequestAccess: true,
          canWithdrawAccessRequest: false,
          requestAccessPath: '/path/to/request',
          withdrawAccessRequestPath: '/path/to/withdraw',
        });

        expect(findHeaderActions().props('project')).toEqual(formattedProject);
      });
    });

    describe('when project loading failed', () => {
      beforeEach(async () => {
        createComponent({
          isLoggedIn: true,
          getProjectByPathHandler: jest.fn().mockRejectedValue(),
        });

        await waitForPromises();
      });

      it('renders header actions with basic project data', () => {
        expect(findHeaderActions().props('project')).toEqual({
          id: mockProject.id,
          availableActions: [ACTION_COPY_ID],
        });
      });

      it('shows alert message', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message:
            'Something went wrong while loading the actions dropdown list. Please refresh the page and try again.',
        });
      });
    });
  });
});
