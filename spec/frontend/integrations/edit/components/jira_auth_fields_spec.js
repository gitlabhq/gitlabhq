import { GlFormRadio, GlFormRadioGroup } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import JiraAuthFields from '~/integrations/edit/components/jira_auth_fields.vue';
import { jiraAuthTypes, jiraAuthTypeFieldProps } from '~/integrations/constants';
import { useIntegrationForm } from '~/integrations/edit/store';

import { mockJiraAuthFields } from '../mock_data';

Vue.use(PiniaVuePlugin);

describe('JiraAuthFields', () => {
  let wrapper;

  const defaultProps = {
    fields: mockJiraAuthFields,
  };

  const createComponent = ({ props } = {}) => {
    const pinia = createTestingPinia({ stubActions: false });
    useIntegrationForm();

    wrapper = shallowMountExtended(JiraAuthFields, {
      propsData: { ...defaultProps, ...props },
      pinia,
    });
  };

  const findAuthTypeRadio = () => wrapper.findComponent(GlFormRadioGroup);
  const findAuthTypeOptions = () => wrapper.findAllComponents(GlFormRadio);
  const findUsernameField = () => wrapper.findByTestId('jira-auth-username');
  const findPasswordField = () => wrapper.findByTestId('jira-auth-password');

  const selectRadioOption = (authType) => findAuthTypeRadio().vm.$emit('input', authType);

  describe('template', () => {
    const mockFieldsWithPasswordValue = [
      mockJiraAuthFields[0],
      mockJiraAuthFields[1],
      {
        ...mockJiraAuthFields[2],
        value: 'hidden',
      },
    ];

    beforeEach(() => {
      createComponent();
    });

    it('renders auth type as radio buttons with correct options', () => {
      expect(findAuthTypeRadio().exists()).toBe(true);

      findAuthTypeOptions().wrappers.forEach((option, index) => {
        expect(option.text()).toBe(JiraAuthFields.authTypeOptions[index].text);
      });
    });

    it('selects "Basic" authentication by default', () => {
      expect(findAuthTypeRadio().attributes('checked')).toBe(String(jiraAuthTypes.BASIC));
    });

    it('selects correct authentication when passed from backend', async () => {
      createComponent({
        props: {
          fields: [
            {
              ...mockJiraAuthFields[0],
              value: 1,
            },
            mockJiraAuthFields[1],
            mockJiraAuthFields[2],
          ],
        },
      });
      await nextTick();

      expect(findAuthTypeRadio().attributes('checked')).toBe('1');
    });

    describe('when "Basic" authentication is selected', () => {
      it('renders username field as required', () => {
        expect(findUsernameField().exists()).toBe(true);
        expect(findUsernameField().props()).toMatchObject({
          title: jiraAuthTypeFieldProps[jiraAuthTypes.BASIC].username,
          required: true,
        });
      });

      it('renders password field with help', () => {
        expect(findPasswordField().exists()).toBe(true);
        expect(findPasswordField().props()).toMatchObject({
          title: jiraAuthTypeFieldProps[jiraAuthTypes.BASIC].password,
          help: jiraAuthTypeFieldProps[jiraAuthTypes.BASIC].passwordHelp,
        });
      });

      it('renders new password title when value is present', () => {
        createComponent({
          props: {
            fields: mockFieldsWithPasswordValue,
          },
        });

        expect(findPasswordField().props('title')).toBe(
          jiraAuthTypeFieldProps[jiraAuthTypes.BASIC].nonEmptyPassword,
        );
      });
    });

    describe('when "Jira personal access token" authentication is selected', () => {
      beforeEach(() => {
        createComponent();

        selectRadioOption(jiraAuthTypes.PAT);
      });

      it('selects "Jira personal access token" authentication', () => {
        expect(findAuthTypeRadio().attributes('checked')).toBe('1');
      });

      it('does not render username field', () => {
        expect(findUsernameField().exists()).toBe(false);
      });

      it('renders password field without help', () => {
        expect(findPasswordField().exists()).toBe(true);
        expect(findPasswordField().props()).toMatchObject({
          title: jiraAuthTypeFieldProps[jiraAuthTypes.PAT].password,
          help: null,
        });
      });

      it('renders new password title when value is present', async () => {
        createComponent({
          props: {
            fields: mockFieldsWithPasswordValue,
          },
        });

        await selectRadioOption(jiraAuthTypes.PAT);

        expect(findPasswordField().props('title')).toBe(
          jiraAuthTypeFieldProps[jiraAuthTypes.PAT].nonEmptyPassword,
        );
      });
    });

    describe('when "Jira Cloud service account" authentication is selected', () => {
      beforeEach(async () => {
        createComponent();
        await selectRadioOption(jiraAuthTypes.SERVICE_ACCOUNT);
      });

      it('selects "Jira Cloud service account" authentication', () => {
        expect(findAuthTypeRadio().attributes('checked')).toBe(
          String(jiraAuthTypes.SERVICE_ACCOUNT),
        );
      });

      it('does not render username field', () => {
        expect(findUsernameField().exists()).toBe(false);
      });

      it('renders password field with service account copy', () => {
        expect(findPasswordField().exists()).toBe(true);
        expect(findPasswordField().props()).toMatchObject({
          title: jiraAuthTypeFieldProps[jiraAuthTypes.SERVICE_ACCOUNT].password,
          help: jiraAuthTypeFieldProps[jiraAuthTypes.SERVICE_ACCOUNT].passwordHelp,
        });
      });

      it('renders new password title when value is present (service account)', async () => {
        createComponent({
          props: { fields: mockFieldsWithPasswordValue },
        });

        await selectRadioOption(jiraAuthTypes.SERVICE_ACCOUNT);

        expect(findPasswordField().props('title')).toBe(
          jiraAuthTypeFieldProps[jiraAuthTypes.SERVICE_ACCOUNT].nonEmptyPassword,
        );
      });
    });
  });
});
