import { GlFormCheckbox, GlFormInput } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';

import JiraIssuesFields from '~/integrations/edit/components/jira_issues_fields.vue';
import { createStore } from '~/integrations/edit/store';

describe('JiraIssuesFields', () => {
  let store;
  let wrapper;

  const defaultProps = {
    showJiraVulnerabilitiesIntegration: true,
  };

  const createComponent = ({
    isInheriting = false,
    mountFn = mountExtended,
    props,
    ...options
  } = {}) => {
    store = createStore({
      defaultState: isInheriting ? {} : undefined,
    });

    wrapper = mountFn(JiraIssuesFields, {
      propsData: { ...defaultProps, ...props },
      store,
      stubs: ['jira-issue-creation-vulnerabilities'],
      ...options,
    });
  };

  const findEnableCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findProjectKeys = () => wrapper.findComponent(GlFormInput);
  const findEnableCheckboxDisabled = () =>
    findEnableCheckbox().find('[type=checkbox]').attributes('disabled');
  const findProjectKeysGroup = () => wrapper.findByTestId('jira-project-keys');
  const findJiraForVulnerabilities = () => wrapper.findByTestId('jira-for-vulnerabilities');
  const setEnableCheckbox = (isEnabled = true) => findEnableCheckbox().vm.$emit('input', isEnabled);

  describe('template', () => {
    describe.each`
      showJiraIssuesIntegration
      ${false}
      ${true}
    `(
      'when showJiraIssuesIntegration = $showJiraIssuesIntegration',
      ({ showJiraIssuesIntegration }) => {
        beforeEach(() => {
          createComponent({
            props: {
              showJiraIssuesIntegration,
            },
          });
        });

        if (showJiraIssuesIntegration) {
          it('renders enable checkbox', () => {
            expect(findEnableCheckbox().exists()).toBe(true);
            expect(findEnableCheckboxDisabled()).toBeUndefined();
          });
        } else {
          it('renders enable checkbox as disabled', () => {
            expect(findEnableCheckbox().exists()).toBe(true);
            expect(findEnableCheckboxDisabled()).toBe('disabled');
          });
        }
      },
    );

    describe('Enable Jira issues checkbox', () => {
      beforeEach(() => {
        createComponent({ props: { initialProjectKey: '' } });
      });

      it('does not render project keys input', () => {
        expect(findProjectKeys().exists()).toBe(false);
      });

      // As per https://vuejs.org/v2/guide/forms.html#Checkbox-1,
      // browsers don't include unchecked boxes in form submissions.
      it('includes issues_enabled as false even if unchecked', () => {
        expect(wrapper.find('input[name="service[issues_enabled]"]').exists()).toBe(true);
      });

      describe('when isInheriting = true', () => {
        it('disables checkbox', () => {
          createComponent({ isInheriting: true });

          expect(findEnableCheckboxDisabled()).toBe('disabled');
        });
      });

      describe('on enable issues', () => {
        it('renders project keys input', async () => {
          await setEnableCheckbox(true);

          expect(findProjectKeys().exists()).toBe(true);
        });
      });
    });

    describe('when initialProjectKeys is provided', () => {
      const projectKeys = 'BE, FE';

      beforeEach(() => {
        createComponent({
          mountFn: shallowMountExtended,
          props: {
            initialEnableJiraIssues: true,
            initialProjectKeys: projectKeys,
          },
        });
      });

      it('renders "Jira project keys" input', () => {
        expect(findProjectKeysGroup().attributes('label')).toBe('Jira project keys');
        expect(findProjectKeys().attributes('value')).toBe(projectKeys);
      });
    });

    describe('when section is issue creation (for vulnarabilities)', () => {
      const jiraIssueType = 'some-jira-issue-type';

      beforeEach(() => {
        createComponent({
          mountFn: shallowMountExtended,
          props: {
            isIssueCreation: true,
            initialVulnerabilitiesIssuetype: jiraIssueType,
          },
        });
      });

      it('renders "Jira for vulnerabilities" component', () => {
        expect(findJiraForVulnerabilities().attributes()).toMatchObject({
          'show-full-feature': 'true',
          'initial-issue-type-id': jiraIssueType,
        });
      });

      it('emits "request-jira-issue-types` when the jira-vulnerabilities component requests to fetch issue types', async () => {
        await findJiraForVulnerabilities().vm.$emit('request-jira-issue-types');

        expect(wrapper.emitted('request-jira-issue-types')).toHaveLength(1);
      });
    });
  });
});
