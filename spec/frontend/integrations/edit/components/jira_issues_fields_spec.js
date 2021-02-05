import { mount } from '@vue/test-utils';

import { GlFormCheckbox, GlFormInput } from '@gitlab/ui';

import JiraIssuesFields from '~/integrations/edit/components/jira_issues_fields.vue';
import eventHub from '~/integrations/edit/event_hub';

describe('JiraIssuesFields', () => {
  let wrapper;

  const defaultProps = {
    editProjectPath: '/edit',
    showJiraIssuesIntegration: true,
    showJiraVulnerabilitiesIntegration: true,
  };

  const createComponent = ({ props, ...options } = {}) => {
    wrapper = mount(JiraIssuesFields, {
      propsData: { ...defaultProps, ...props },
      stubs: ['jira-issue-creation-vulnerabilities'],
      ...options,
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findEnableCheckbox = () => wrapper.find(GlFormCheckbox);
  const findProjectKey = () => wrapper.find(GlFormInput);
  const expectedBannerText = 'This is a Premium feature';
  const findJiraForVulnerabilities = () => wrapper.find('[data-testid="jira-for-vulnerabilities"]');
  const setEnableCheckbox = async (isEnabled = true) =>
    findEnableCheckbox().vm.$emit('input', isEnabled);

  describe('template', () => {
    describe('upgrade banner for non-Premium user', () => {
      beforeEach(() => {
        createComponent({ props: { initialProjectKey: '', showJiraIssuesIntegration: false } });
      });

      it('shows upgrade banner', () => {
        expect(wrapper.text()).toContain(expectedBannerText);
      });

      it('does not show checkbox and input field', () => {
        expect(findEnableCheckbox().exists()).toBe(false);
        expect(findProjectKey().exists()).toBe(false);
      });
    });

    describe('Enable Jira issues checkbox', () => {
      beforeEach(() => {
        createComponent({ props: { initialProjectKey: '' } });
      });

      it('does not show upgrade banner', () => {
        expect(wrapper.text()).not.toContain(expectedBannerText);
      });

      // As per https://vuejs.org/v2/guide/forms.html#Checkbox-1,
      // browsers don't include unchecked boxes in form submissions.
      it('includes issues_enabled as false even if unchecked', () => {
        expect(wrapper.find('input[name="service[issues_enabled]"]').exists()).toBe(true);
      });

      it('disables project_key input', () => {
        expect(findProjectKey().attributes('disabled')).toBe('disabled');
      });

      it('does not require project_key', () => {
        expect(findProjectKey().attributes('required')).toBeUndefined();
      });

      describe('on enable issues', () => {
        it('enables project_key input', async () => {
          await setEnableCheckbox(true);

          expect(findProjectKey().attributes('disabled')).toBeUndefined();
        });

        it('requires project_key input', async () => {
          await setEnableCheckbox(true);

          expect(findProjectKey().attributes('required')).toBe('required');
        });
      });
    });

    it('contains link to editProjectPath', () => {
      createComponent();

      expect(wrapper.find(`a[href="${defaultProps.editProjectPath}"]`).exists()).toBe(true);
    });

    describe('GitLab issues warning', () => {
      const expectedText = 'Consider disabling GitLab issues';

      it('contains warning when GitLab issues is enabled', () => {
        createComponent();

        expect(wrapper.text()).toContain(expectedText);
      });

      it('does not contain warning when GitLab issues is disabled', () => {
        createComponent({ props: { gitlabIssuesEnabled: false } });

        expect(wrapper.text()).not.toContain(expectedText);
      });
    });

    describe('Vulnerabilities creation', () => {
      beforeEach(() => {
        createComponent({ provide: { glFeatures: { jiraForVulnerabilities: true } } });
      });

      it.each([true, false])(
        'shows the jira-vulnerabilities component correctly when jira issues enables is set to "%s"',
        async (hasJiraIssuesEnabled) => {
          await setEnableCheckbox(hasJiraIssuesEnabled);

          expect(findJiraForVulnerabilities().exists()).toBe(hasJiraIssuesEnabled);
        },
      );

      it('emits "getJiraIssueTypes" to the eventHub when the jira-vulnerabilities component requests to fetch issue types', async () => {
        const eventHubEmitSpy = jest.spyOn(eventHub, '$emit');

        await setEnableCheckbox(true);
        await findJiraForVulnerabilities().vm.$emit('request-get-issue-types');

        expect(eventHubEmitSpy).toHaveBeenCalledWith('getJiraIssueTypes');
      });

      describe('with "jiraForVulnerabilities" feature flag disabled', () => {
        beforeEach(async () => {
          createComponent({
            provide: { glFeatures: { jiraForVulnerabilities: false } },
          });
        });

        it('does not show section', () => {
          expect(findJiraForVulnerabilities().exists()).toBe(false);
        });
      });
    });
  });
});
