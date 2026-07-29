import {
  GlAlert,
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlFormSelect,
  GlLabel,
  GlSearchBoxByType,
  GlTableLite,
} from '@gitlab/ui';
import { getByRole } from '@testing-library/dom';
import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import AxiosMockAdapter from 'axios-mock-adapter';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import JiraImportForm from '~/jira_import/components/jira_import_form.vue';
import getJiraImportDetailsQuery from '~/jira_import/queries/get_jira_import_details.query.graphql';
import getJiraUserMappingMutation from '~/jira_import/queries/get_jira_user_mapping.mutation.graphql';
import initiateJiraImportMutation from '~/jira_import/queries/initiate_jira_import.mutation.graphql';
import searchProjectMembersQuery from '~/jira_import/queries/search_project_members.query.graphql';
import { debounceWait, userMappingsPageSize } from '~/jira_import/utils/constants';
import axios from '~/lib/utils/axios_utils';
import {
  getJiraImportDetailsQueryResponse,
  imports,
  issuesPath,
  jiraProjects,
  jiraUsersResponse,
  projectPath,
  userMappings as defaultUserMappings,
} from '../mock_data';

Vue.use(VueApollo);

const jiraUserMappingResponse = ({ jiraUsers = defaultUserMappings, errors = [] } = {}) => ({
  data: {
    jiraImportUsers: {
      jiraUsers,
      errors,
      __typename: 'JiraImportUsersPayload',
    },
  },
});

const projectMembersResponse = (users = []) => ({
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      projectMembers: {
        nodes: users.map((user, index) => ({
          id: `gid://gitlab/ProjectMember/${index}`,
          user,
          __typename: 'ProjectMember',
        })),
        __typename: 'MemberInterfaceConnection',
      },
      __typename: 'Project',
    },
  },
});

const initiateJiraImportResponse = ({ errors = [] } = {}) => ({
  data: {
    jiraImportStart: {
      jiraImport: {
        jiraProjectKey: 'MTG',
        scheduledAt: '2020-04-09T16:17:18+00:00',
        scheduledBy: {
          id: 'gid://gitlab/User/3',
          name: 'Jane Doe',
          __typename: 'User',
        },
        __typename: 'JiraImport',
      },
      errors,
      __typename: 'JiraImportStartPayload',
    },
  },
});

describe('JiraImportForm', () => {
  let axiosMock;
  let wrapper;

  const currentUsername = 'mrgitlab';

  const getAlert = () => wrapper.findComponent(GlAlert);

  const getSelectDropdown = () => wrapper.findComponent(GlFormSelect);

  const getContinueButton = () => wrapper.findComponent(GlButton);

  const getCancelButton = () => wrapper.findAllComponents(GlButton).at(1);

  const getLabel = () => wrapper.findComponent(GlLabel);

  const getTable = () => wrapper.findComponent(GlTableLite);

  const getUserDropdown = () => getTable().findComponent(GlDropdown);

  const getHeader = (name) => getByRole(wrapper.element, 'columnheader', { name });

  const findLoadMoreUsersButton = () =>
    wrapper.findComponent('[data-testid="load-more-users-button"]');

  const mountComponent = async ({
    mountFunction = shallowMount,
    userMappingHandler = jest.fn().mockResolvedValue(jiraUserMappingResponse()),
    searchMembersHandler = jest.fn().mockResolvedValue(projectMembersResponse()),
    initiateImportHandler = jest.fn().mockResolvedValue(initiateJiraImportResponse()),
  } = {}) => {
    const apolloProvider = createMockApollo([
      [getJiraUserMappingMutation, userMappingHandler],
      [searchProjectMembersQuery, searchMembersHandler],
      [initiateJiraImportMutation, initiateImportHandler],
    ]);

    // `addInProgressImportToStore` runs as the import mutation's `update` and
    // reads the import details query back out of the cache.
    apolloProvider.defaultClient.writeQuery({
      query: getJiraImportDetailsQuery,
      variables: { fullPath: projectPath },
      ...getJiraImportDetailsQueryResponse(),
    });

    wrapper = mountFunction(JiraImportForm, {
      apolloProvider,
      propsData: {
        issuesPath,
        jiraImports: imports,
        jiraProjects,
        projectPath,
      },
      currentUsername,
    });

    await waitForPromises();
  };

  const selectProject = async (jiraProjectKey) => {
    getSelectDropdown().vm.$emit('input', jiraProjectKey);
    await nextTick();
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('select dropdown project selection', () => {
    it('is shown', async () => {
      await mountComponent();

      expect(getSelectDropdown().exists()).toBe(true);
    });

    it('contains a list of Jira projects to select from', async () => {
      await mountComponent({ mountFunction: mount });

      getSelectDropdown()
        .findAll('option')
        .wrappers.forEach((optionEl, index) => {
          expect(optionEl.text()).toBe(jiraProjects[index].text);
        });
    });

    describe('when selected project has been imported before', () => {
      it('shows jira-import::MTG-3 label since project MTG has been imported 2 time before', async () => {
        await mountComponent();
        await selectProject('MTG');

        expect(getLabel().props('title')).toBe('jira-import::MTG-3');
      });

      it('shows warning alert to explain project MTG has been imported 2 times before', async () => {
        await mountComponent({ mountFunction: mount });
        await selectProject('MTG');

        expect(getAlert().text()).toBe(
          'You have imported from this project 2 times before. Each new import will create duplicate issues.',
        );
      });
    });

    describe('when selected project has not been imported before', () => {
      beforeEach(async () => {
        await mountComponent();
        await selectProject('MJP');
      });

      it('shows jira-import::MJP-1 label since project MJP has not been imported before', () => {
        expect(getLabel().props('title')).toBe('jira-import::MJP-1');
      });

      it('does not show warning alert since project MJP has not been imported before', () => {
        expect(getAlert().exists()).toBe(false);
      });
    });
  });

  describe('form information', () => {
    beforeEach(async () => {
      await mountComponent();
    });

    it('shows a heading for the user mapping section', () => {
      expect(
        getByRole(wrapper.element, 'heading', { name: 'Jira-GitLab user mapping template' })
          .innerText,
      ).toBe('Jira-GitLab user mapping template');
    });

    it('shows information to the user', () => {
      expect(wrapper.find('p').text()).toBe(
        'Jira users have been imported from the configured Jira instance. They can be mapped by selecting a GitLab user from the dropdown in the "GitLab username" column. When the form appears, the dropdown defaults to the user conducting the import.',
      );
    });
  });

  describe('table', () => {
    describe('headers', () => {
      beforeEach(async () => {
        await mountComponent({ mountFunction: mount });
      });

      it('has a "Jira display name" column', () => {
        expect(getHeader('Jira display name').innerText).toBe('Jira display name');
      });

      it('has an "arrow" column', () => {
        expect(getHeader('Arrow').getAttribute('aria-label')).toBe('Arrow');
      });

      it('has a "GitLab username" column', () => {
        expect(getHeader('GitLab username').innerText).toBe('GitLab username');
      });
    });

    describe('body', () => {
      it('shows all user mappings', async () => {
        await mountComponent({ mountFunction: mount });

        expect(getTable().findAll('tbody tr')).toHaveLength(defaultUserMappings.length);
      });

      describe('when there is no Jira->GitLab user mapping', () => {
        it('shows the logged in user in the dropdown', async () => {
          await mountComponent({
            mountFunction: mount,
            userMappingHandler: jest.fn().mockResolvedValue(
              jiraUserMappingResponse({
                jiraUsers: [
                  {
                    jiraAccountId: 'aei23f98f-q23fj98qfj',
                    jiraDisplayName: 'Jane Doe',
                    jiraEmail: 'janedoe@example.com',
                    gitlabId: null,
                    gitlabName: null,
                    gitlabUsername: null,
                    __typename: 'JiraUser',
                  },
                ],
              }),
            ),
          });

          expect(getUserDropdown().text()).toContain(currentUsername);
        });
      });

      describe('when there is a Jira->GitLab user mapping', () => {
        it('shows the mapped user in the dropdown', async () => {
          const gitlabUsername = 'mai';

          await mountComponent({
            mountFunction: mount,
            userMappingHandler: jest.fn().mockResolvedValue(
              jiraUserMappingResponse({
                jiraUsers: [
                  {
                    jiraAccountId: 'aei23f98f-q23fj98qfj',
                    jiraDisplayName: 'Jane Doe',
                    jiraEmail: 'janedoe@example.com',
                    gitlabId: 14,
                    gitlabName: 'Mai',
                    gitlabUsername,
                    __typename: 'JiraUser',
                  },
                ],
              }),
            ),
          });

          expect(getUserDropdown().text()).toContain(gitlabUsername);
        });
      });
    });
  });

  describe('member search', () => {
    describe('when searching for a member', () => {
      let searchMembersHandler;

      beforeEach(async () => {
        searchMembersHandler = jest
          .fn()
          .mockResolvedValueOnce(projectMembersResponse())
          .mockResolvedValue(
            projectMembersResponse([
              {
                id: 'gid://gitlab/User/7',
                name: 'Frederic Chopin',
                username: 'fchopin',
                __typename: 'UserCore',
              },
            ]),
          );

        await mountComponent({ mountFunction: mount, searchMembersHandler });

        wrapper.findComponent(GlSearchBoxByType).vm.$emit('input', 'fred');

        jest.advanceTimersByTime(debounceWait);
        await waitForPromises();
      });

      it('makes a GraphQL call', () => {
        expect(searchMembersHandler).toHaveBeenLastCalledWith({
          fullPath: projectPath,
          search: 'fred',
        });
      });

      it('updates the user list', () => {
        expect(getUserDropdown().findAllComponents(GlDropdownItem)).toHaveLength(1);
        expect(getUserDropdown().findComponent(GlDropdownItem).text()).toContain(
          'fchopin (Frederic Chopin)',
        );
      });
    });
  });

  describe('buttons', () => {
    describe('"Continue" button', () => {
      it('is shown', async () => {
        await mountComponent();

        expect(getContinueButton().text()).toBe('Continue');
      });

      it('is in loading state when the form is submitting', async () => {
        await mountComponent({
          // Never resolves, so the form stays in the submitting state
          initiateImportHandler: jest.fn().mockReturnValue(new Promise(() => {})),
        });
        await selectProject('MTG');

        wrapper.find('form').trigger('submit');
        await nextTick();

        expect(getContinueButton().props('loading')).toBe(true);
      });
    });

    describe('"Cancel" button', () => {
      beforeEach(async () => {
        await mountComponent();
      });

      it('is shown', () => {
        expect(getCancelButton().text()).toBe('Cancel');
      });

      it('links to the Issues page', () => {
        expect(getCancelButton().attributes('href')).toBe(issuesPath);
      });
    });
  });

  describe('submitting the form', () => {
    it('initiates the Jira import mutation with the expected arguments', async () => {
      const initiateImportHandler = jest.fn().mockResolvedValue(initiateJiraImportResponse());

      await mountComponent({ initiateImportHandler });
      await selectProject('MTG');

      wrapper.find('form').trigger('submit');
      await waitForPromises();

      expect(initiateImportHandler).toHaveBeenCalledWith({
        input: {
          jiraProjectKey: 'MTG',
          projectPath,
          usersMapping: [
            {
              jiraAccountId: 'aei23f98f-q23fj98qfj',
              gitlabId: 15,
            },
            {
              jiraAccountId: 'fu39y8t34w-rq3u289t3h4i',
              gitlabId: null,
            },
          ],
        },
      });
    });
  });

  describe('on mount GraphQL user mapping mutation', () => {
    it('is called with the expected arguments', async () => {
      const userMappingHandler = jest.fn().mockResolvedValue(jiraUserMappingResponse());

      await mountComponent({ userMappingHandler });

      expect(userMappingHandler).toHaveBeenCalledWith({
        input: {
          projectPath,
          startAt: 0,
        },
      });
    });

    describe('when there is an error when called', () => {
      beforeEach(async () => {
        await mountComponent({
          userMappingHandler: jest.fn().mockRejectedValue(new Error('Network error')),
        });
      });

      it('emits an error', () => {
        expect(wrapper.emitted('error')).toEqual([
          ['There was an error retrieving the Jira users.'],
        ]);
      });
    });
  });

  describe('load more users button', () => {
    describe('when all users have been loaded', () => {
      it('is not shown', async () => {
        await mountComponent();

        expect(findLoadMoreUsersButton().exists()).toBe(false);
      });
    });

    describe('when all users have not been loaded', () => {
      it('is shown', async () => {
        await mountComponent({
          userMappingHandler: jest
            .fn()
            .mockResolvedValue(jiraUserMappingResponse({ jiraUsers: jiraUsersResponse })),
        });

        expect(findLoadMoreUsersButton().exists()).toBe(true);
      });
    });

    describe('when clicked', () => {
      it('calls the GraphQL user mapping mutation for the next page', async () => {
        const userMappingHandler = jest
          .fn()
          .mockResolvedValue(jiraUserMappingResponse({ jiraUsers: jiraUsersResponse }));

        await mountComponent({ userMappingHandler });

        findLoadMoreUsersButton().vm.$emit('click');
        await waitForPromises();

        expect(userMappingHandler).toHaveBeenLastCalledWith({
          input: {
            projectPath,
            startAt: userMappingsPageSize,
          },
        });
      });
    });
  });
});
