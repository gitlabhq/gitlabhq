import { GlFormRadio, GlFormRadioGroup } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import JiraAuthFields from '~/integrations/edit/components/jira_auth_fields.vue';
import { jiraAuthTypeFieldProps } from '~/integrations/constants';
import { createStore } from '~/integrations/edit/store';

import { mockJiraAuthFields } from '../mock_data';

describe('JiraAuthFields', () => {
  let wrapper;

  const defaultProps = {
    fields: mockJiraAuthFields,
  };

  const createComponent = ({ props } = {}) => {
    const store = createStore();

    wrapper = shallowMountExtended(JiraAuthFields, {
      propsData: { ...defaultProps, ...props },
      store,
    });
  };

  const findAuthTypeRadio = () => wrapper.findComponent(GlFormRadioGroup);
  const findAuthTypeOptions = () => wrapper.findAllComponents(GlFormRadio);
  const findUsernameField = () => wrapper.findByTestId('jira-auth-username');
  const findPasswordField = () => wrapper.findByTestId('jira-auth-password');

  const selectRadioOption = (index) => findAuthTypeRadio().vm.$emit('input', index);

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
      expect(findAuthTypeRadio().attributes('checked')).toBe('0');
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
          title: jiraAuthTypeFieldProps[0].username,
          required: true,
        });
      });

      it('renders password field with help', () => {
        expect(findPasswordField().exists()).toBe(true);
        expect(findPasswordField().props()).toMatchObject({
          title: jiraAuthTypeFieldProps[0].password,
          help: jiraAuthTypeFieldProps[0].passwordHelp,
        });
      });

      it('renders new password title when value is present', () => {
        createComponent({
          props: {
            fields: mockFieldsWithPasswordValue,
          },
        });

        expect(findPasswordField().props('title')).toBe(jiraAuthTypeFieldProps[0].nonEmptyPassword);
      });
    });

    describe('when "Jira personal access token" authentication is selected', () => {
      beforeEach(() => {
        createComponent();

        selectRadioOption(1);
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
          title: jiraAuthTypeFieldProps[1].password,
          help: null,
        });
      });

      it('renders new password title when value is present', async () => {
        createComponent({
          props: {
            fields: mockFieldsWithPasswordValue,
          },
        });

        await selectRadioOption(1);

        expect(findPasswordField().props('title')).toBe(jiraAuthTypeFieldProps[1].nonEmptyPassword);
      });
    });
  });
});
