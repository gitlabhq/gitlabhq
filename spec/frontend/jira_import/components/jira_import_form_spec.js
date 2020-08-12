import { GlAlert, GlButton, GlNewDropdown, GlFormSelect, GlLabel, GlTable } from '@gitlab/ui';
import { getByRole } from '@testing-library/dom';
import { mount, shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import JiraImportForm from '~/jira_import/components/jira_import_form.vue';
import {
  imports,
  issuesPath,
  jiraProjects,
  userMappings as defaultUserMappings,
} from '../mock_data';

describe('JiraImportForm', () => {
  let axiosMock;
  let wrapper;

  const currentUsername = 'mrgitlab';

  const getAlert = () => wrapper.find(GlAlert);

  const getSelectDropdown = () => wrapper.find(GlFormSelect);

  const getContinueButton = () => wrapper.find(GlButton);

  const getCancelButton = () => wrapper.findAll(GlButton).at(1);

  const getLabel = () => wrapper.find(GlLabel);

  const getTable = () => wrapper.find(GlTable);

  const getUserDropdown = () => getTable().find(GlNewDropdown);

  const getHeader = name => getByRole(wrapper.element, 'columnheader', { name });

  const mountComponent = ({
    isSubmitting = false,
    selectedProject = 'MTG',
    userMappings = defaultUserMappings,
    mountFunction = shallowMount,
  } = {}) =>
    mountFunction(JiraImportForm, {
      propsData: {
        isSubmitting,
        issuesPath,
        jiraImports: imports,
        jiraProjects,
        projectId: '5',
        userMappings,
      },
      data: () => ({
        isFetching: false,
        searchTerm: '',
        selectedProject,
        selectState: null,
        users: [],
      }),
      currentUsername,
    });

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
    wrapper.destroy();
    wrapper = null;
  });

  describe('select dropdown project selection', () => {
    it('is shown', () => {
      wrapper = mountComponent();

      expect(wrapper.contains(GlFormSelect)).toBe(true);
    });

    it('contains a list of Jira projects to select from', () => {
      wrapper = mountComponent({ mountFunction: mount });

      getSelectDropdown()
        .findAll('option')
        .wrappers.forEach((optionEl, index) => {
          expect(optionEl.text()).toBe(jiraProjects[index].text);
        });
    });

    describe('when selected project has been imported before', () => {
      it('shows jira-import::MTG-3 label since project MTG has been imported 2 time before', () => {
        wrapper = mountComponent();

        expect(getLabel().props('title')).toBe('jira-import::MTG-3');
      });

      it('shows warning alert to explain project MTG has been imported 2 times before', () => {
        wrapper = mountComponent({ mountFunction: mount });

        expect(getAlert().text()).toBe(
          'You have imported from this project 2 times before. Each new import will create duplicate issues.',
        );
      });
    });

    describe('when selected project has not been imported before', () => {
      beforeEach(() => {
        wrapper = mountComponent({ selectedProject: 'MJP' });
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
    beforeEach(() => {
      wrapper = mountComponent();
    });

    it('shows a heading for the user mapping section', () => {
      expect(
        getByRole(wrapper.element, 'heading', { name: 'Jira-GitLab user mapping template' }),
      ).toBeTruthy();
    });

    it('shows information to the user', () => {
      expect(wrapper.find('p').text()).toBe(
        'Jira users have been imported from the configured Jira instance. They can be mapped by selecting a GitLab user from the dropdown in the "GitLab username" column. When the form appears, the dropdown defaults to the user conducting the import.',
      );
    });
  });

  describe('table', () => {
    describe('headers', () => {
      beforeEach(() => {
        wrapper = mountComponent({ mountFunction: mount });
      });

      it('has a "Jira display name" column', () => {
        expect(getHeader('Jira display name')).toBeTruthy();
      });

      it('has an "arrow" column', () => {
        expect(getHeader('Arrow')).toBeTruthy();
      });

      it('has a "GitLab username" column', () => {
        expect(getHeader('GitLab username')).toBeTruthy();
      });
    });

    describe('body', () => {
      it('shows all user mappings', () => {
        wrapper = mountComponent({ mountFunction: mount });

        expect(getTable().findAll('tbody tr')).toHaveLength(2);
      });

      it('shows correct information in each cell', () => {
        wrapper = mountComponent({ mountFunction: mount });

        expect(getTable().element).toMatchSnapshot();
      });

      describe('when there is no Jira->GitLab user mapping', () => {
        it('shows the logged in user in the dropdown', () => {
          wrapper = mountComponent({
            mountFunction: mount,
            userMappings: [
              {
                jiraAccountId: 'aei23f98f-q23fj98qfj',
                jiraDisplayName: 'Jane Doe',
                jiraEmail: 'janedoe@example.com',
                gitlabId: undefined,
                gitlabUsername: undefined,
              },
            ],
          });

          expect(getUserDropdown().text()).toContain(currentUsername);
        });
      });

      describe('when there is a Jira->GitLab user mapping', () => {
        it('shows the mapped user in the dropdown', () => {
          const gitlabUsername = 'mai';

          wrapper = mountComponent({
            mountFunction: mount,
            userMappings: [
              {
                jiraAccountId: 'aei23f98f-q23fj98qfj',
                jiraDisplayName: 'Jane Doe',
                jiraEmail: 'janedoe@example.com',
                gitlabId: 14,
                gitlabUsername,
              },
            ],
          });

          expect(getUserDropdown().text()).toContain(gitlabUsername);
        });
      });
    });
  });

  describe('buttons', () => {
    describe('"Continue" button', () => {
      it('is shown', () => {
        wrapper = mountComponent();

        expect(getContinueButton().text()).toBe('Continue');
      });

      it('is in loading state when the form is submitting', async () => {
        wrapper = mountComponent({ isSubmitting: true });

        expect(getContinueButton().props('loading')).toBe(true);
      });
    });

    describe('"Cancel" button', () => {
      beforeEach(() => {
        wrapper = mountComponent();
      });

      it('is shown', () => {
        expect(getCancelButton().text()).toBe('Cancel');
      });

      it('links to the Issues page', () => {
        expect(getCancelButton().attributes('href')).toBe(issuesPath);
      });
    });
  });

  describe('form', () => {
    it('emits an "initiateJiraImport" event with the selected dropdown value when submitted', () => {
      const selectedProject = 'MTG';

      wrapper = mountComponent({ selectedProject });

      wrapper.find('form').trigger('submit');

      expect(wrapper.emitted('initiateJiraImport')[0]).toEqual([selectedProject]);
    });
  });
});
