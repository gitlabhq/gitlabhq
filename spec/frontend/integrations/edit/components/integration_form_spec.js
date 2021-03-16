import { shallowMount } from '@vue/test-utils';
import { setHTMLFixture } from 'helpers/fixtures';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { mockIntegrationProps } from 'jest/integrations/edit/mock_data';
import ActiveCheckbox from '~/integrations/edit/components/active_checkbox.vue';
import ConfirmationModal from '~/integrations/edit/components/confirmation_modal.vue';
import DynamicField from '~/integrations/edit/components/dynamic_field.vue';
import IntegrationForm from '~/integrations/edit/components/integration_form.vue';
import JiraIssuesFields from '~/integrations/edit/components/jira_issues_fields.vue';
import JiraTriggerFields from '~/integrations/edit/components/jira_trigger_fields.vue';
import OverrideDropdown from '~/integrations/edit/components/override_dropdown.vue';
import ResetConfirmationModal from '~/integrations/edit/components/reset_confirmation_modal.vue';
import TriggerFields from '~/integrations/edit/components/trigger_fields.vue';
import { integrationLevels } from '~/integrations/edit/constants';
import { createStore } from '~/integrations/edit/store';

describe('IntegrationForm', () => {
  let wrapper;

  const createComponent = ({
    customStateProps = {},
    featureFlags = {},
    initialState = {},
    props = {},
  } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(IntegrationForm, {
        propsData: { ...props },
        store: createStore({
          customState: { ...mockIntegrationProps, ...customStateProps },
          ...initialState,
        }),
        stubs: {
          OverrideDropdown,
          ActiveCheckbox,
          ConfirmationModal,
          JiraTriggerFields,
          TriggerFields,
        },
        provide: {
          glFeatures: featureFlags,
        },
      }),
    );
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findOverrideDropdown = () => wrapper.find(OverrideDropdown);
  const findActiveCheckbox = () => wrapper.find(ActiveCheckbox);
  const findConfirmationModal = () => wrapper.find(ConfirmationModal);
  const findResetConfirmationModal = () => wrapper.find(ResetConfirmationModal);
  const findResetButton = () => wrapper.find('[data-testid="reset-button"]');
  const findJiraTriggerFields = () => wrapper.find(JiraTriggerFields);
  const findJiraIssuesFields = () => wrapper.find(JiraIssuesFields);
  const findTriggerFields = () => wrapper.find(TriggerFields);

  describe('template', () => {
    describe('showActive is true', () => {
      it('renders ActiveCheckbox', () => {
        createComponent();

        expect(findActiveCheckbox().exists()).toBe(true);
      });
    });

    describe('showActive is false', () => {
      it('does not render ActiveCheckbox', () => {
        createComponent({
          customStateProps: {
            showActive: false,
          },
        });

        expect(findActiveCheckbox().exists()).toBe(false);
      });
    });

    describe('integrationLevel is instance', () => {
      it('renders ConfirmationModal', () => {
        createComponent({
          customStateProps: {
            integrationLevel: integrationLevels.INSTANCE,
          },
        });

        expect(findConfirmationModal().exists()).toBe(true);
      });

      describe('resetPath is empty', () => {
        it('does not render ResetConfirmationModal and button', () => {
          createComponent({
            customStateProps: {
              integrationLevel: integrationLevels.INSTANCE,
            },
          });

          expect(findResetButton().exists()).toBe(false);
          expect(findResetConfirmationModal().exists()).toBe(false);
        });
      });

      describe('resetPath is present', () => {
        it('renders ResetConfirmationModal and button', () => {
          createComponent({
            customStateProps: {
              integrationLevel: integrationLevels.INSTANCE,
              resetPath: 'resetPath',
            },
          });

          expect(findResetButton().exists()).toBe(true);
          expect(findResetConfirmationModal().exists()).toBe(true);
        });
      });
    });

    describe('integrationLevel is group', () => {
      it('renders ConfirmationModal', () => {
        createComponent({
          customStateProps: {
            integrationLevel: integrationLevels.GROUP,
          },
        });

        expect(findConfirmationModal().exists()).toBe(true);
      });

      describe('resetPath is empty', () => {
        it('does not render ResetConfirmationModal and button', () => {
          createComponent({
            customStateProps: {
              integrationLevel: integrationLevels.GROUP,
            },
          });

          expect(findResetButton().exists()).toBe(false);
          expect(findResetConfirmationModal().exists()).toBe(false);
        });
      });

      describe('resetPath is present', () => {
        it('renders ResetConfirmationModal and button', () => {
          createComponent({
            customStateProps: {
              integrationLevel: integrationLevels.GROUP,
              resetPath: 'resetPath',
            },
          });

          expect(findResetButton().exists()).toBe(true);
          expect(findResetConfirmationModal().exists()).toBe(true);
        });
      });
    });

    describe('integrationLevel is project', () => {
      it('does not render ConfirmationModal', () => {
        createComponent({
          customStateProps: {
            integrationLevel: 'project',
          },
        });

        expect(findConfirmationModal().exists()).toBe(false);
      });

      it('does not render ResetConfirmationModal and button', () => {
        createComponent({
          customStateProps: {
            integrationLevel: 'project',
            resetPath: 'resetPath',
          },
        });

        expect(findResetButton().exists()).toBe(false);
        expect(findResetConfirmationModal().exists()).toBe(false);
      });
    });

    describe('type is "slack"', () => {
      beforeEach(() => {
        createComponent({
          customStateProps: { type: 'slack' },
        });
      });

      it('does not render JiraTriggerFields', () => {
        expect(findJiraTriggerFields().exists()).toBe(false);
      });

      it('does not render JiraIssuesFields', () => {
        expect(findJiraIssuesFields().exists()).toBe(false);
      });
    });

    describe('type is "jira"', () => {
      it('renders JiraTriggerFields', () => {
        createComponent({
          customStateProps: { type: 'jira' },
        });

        expect(findJiraTriggerFields().exists()).toBe(true);
      });
    });

    describe('triggerEvents is present', () => {
      it('renders TriggerFields', () => {
        const events = [{ title: 'push' }];
        const type = 'slack';

        createComponent({
          customStateProps: {
            triggerEvents: events,
            type,
          },
        });

        expect(findTriggerFields().exists()).toBe(true);
        expect(findTriggerFields().props('events')).toBe(events);
        expect(findTriggerFields().props('type')).toBe(type);
      });
    });

    describe('fields is present', () => {
      it('renders DynamicField for each field', () => {
        const fields = [
          { name: 'username', type: 'text' },
          { name: 'API token', type: 'password' },
        ];

        createComponent({
          customStateProps: {
            fields,
          },
        });

        const dynamicFields = wrapper.findAll(DynamicField);

        expect(dynamicFields).toHaveLength(2);
        dynamicFields.wrappers.forEach((field, index) => {
          expect(field.props()).toMatchObject(fields[index]);
        });
      });
    });

    describe('defaultState state is null', () => {
      it('does not render OverrideDropdown', () => {
        createComponent({
          initialState: {
            defaultState: null,
          },
        });

        expect(findOverrideDropdown().exists()).toBe(false);
      });
    });

    describe('defaultState state is an object', () => {
      it('renders OverrideDropdown', () => {
        createComponent({
          initialState: {
            defaultState: {
              ...mockIntegrationProps,
            },
          },
        });

        expect(findOverrideDropdown().exists()).toBe(true);
      });
    });

    describe('with `helpHtml` prop', () => {
      const mockTestId = 'jest-help-html-test';

      setHTMLFixture(`
        <div data-testid="${mockTestId}">
          <svg class="gl-icon">
            <use></use>
          </svg>
        </div>
      `);

      it('renders `helpHtml`', async () => {
        const mockHelpHtml = document.querySelector(`[data-testid="${mockTestId}"]`);

        createComponent({
          props: {
            helpHtml: mockHelpHtml.outerHTML,
          },
        });

        const helpHtml = wrapper.findByTestId(mockTestId);

        expect(helpHtml.isVisible()).toBe(true);
        expect(helpHtml.find('svg').isVisible()).toBe(true);
      });
    });
  });
});
