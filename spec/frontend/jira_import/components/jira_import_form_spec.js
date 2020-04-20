import { GlAvatar, GlButton, GlFormSelect, GlLabel } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import JiraImportForm from '~/jira_import/components/jira_import_form.vue';

const mountComponent = ({ mountType } = {}) => {
  const mountFunction = mountType === 'mount' ? mount : shallowMount;

  return mountFunction(JiraImportForm, {
    propsData: {
      issuesPath: 'gitlab-org/gitlab-test/-/issues',
      jiraProjects: [
        {
          text: 'My Jira Project',
          value: 'MJP',
        },
        {
          text: 'My Second Jira Project',
          value: 'MSJP',
        },
        {
          text: 'Migrate to GitLab',
          value: 'MTG',
        },
      ],
    },
  });
};

describe('JiraImportForm', () => {
  let wrapper;

  const getCancelButton = () => wrapper.findAll(GlButton).at(1);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('select dropdown', () => {
    it('is shown', () => {
      wrapper = mountComponent();

      expect(wrapper.find(GlFormSelect).exists()).toBe(true);
    });

    it('contains a list of Jira projects to select from', () => {
      wrapper = mountComponent({ mountType: 'mount' });

      const optionItems = ['My Jira Project', 'My Second Jira Project', 'Migrate to GitLab'];

      wrapper
        .find(GlFormSelect)
        .findAll('option')
        .wrappers.forEach((optionEl, index) => {
          expect(optionEl.text()).toBe(optionItems[index]);
        });
    });
  });

  describe('form information', () => {
    beforeEach(() => {
      wrapper = mountComponent();
    });

    it('shows a label which will be applied to imported Jira projects', () => {
      expect(wrapper.find(GlLabel).attributes('title')).toBe('jira-import::KEY-1');
    });

    it('shows information to the user', () => {
      expect(wrapper.find('p').text()).toBe(
        "For each Jira issue successfully imported, we'll create a new GitLab issue with the following data:",
      );
    });

    it('shows jira.issue.summary for the Title', () => {
      expect(wrapper.find('[id="jira-project-title"]').text()).toBe('jira.issue.summary');
    });

    it('shows an avatar for the Reporter', () => {
      expect(wrapper.find(GlAvatar).exists()).toBe(true);
    });

    it('shows jira.issue.description.content for the Description', () => {
      expect(wrapper.find('[id="jira-project-description"]').text()).toBe(
        'jira.issue.description.content',
      );
    });
  });

  describe('Next button', () => {
    beforeEach(() => {
      wrapper = mountComponent();
    });

    it('is shown', () => {
      expect(wrapper.find(GlButton).text()).toBe('Next');
    });
  });

  describe('Cancel button', () => {
    beforeEach(() => {
      wrapper = mountComponent();
    });

    it('is shown', () => {
      expect(getCancelButton().text()).toBe('Cancel');
    });

    it('links to the Issues page', () => {
      expect(getCancelButton().attributes('href')).toBe('gitlab-org/gitlab-test/-/issues');
    });
  });

  it('emits an "initiateJiraImport" event with the selected dropdown value when submitted', () => {
    const selectedOption = 'MTG';

    wrapper = mountComponent();
    wrapper.setData({
      selectedOption,
    });

    wrapper.find('form').trigger('submit');

    expect(wrapper.emitted('initiateJiraImport')[0]).toEqual([selectedOption]);
  });
});
