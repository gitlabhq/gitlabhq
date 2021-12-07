import { setHTMLFixture } from 'helpers/fixtures';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

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
import {
  integrationLevels,
  TEST_INTEGRATION_EVENT,
  SAVE_INTEGRATION_EVENT,
} from '~/integrations/constants';
import { createStore } from '~/integrations/edit/store';
import eventHub from '~/integrations/edit/event_hub';

jest.mock('~/integrations/edit/event_hub');

describe('IntegrationForm', () => {
  let wrapper;
  let dispatch;

  const createComponent = ({
    customStateProps = {},
    featureFlags = {},
    initialState = {},
    props = {},
  } = {}) => {
    const store = createStore({
      customState: { ...mockIntegrationProps, ...customStateProps },
      ...initialState,
    });
    dispatch = jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMountExtended(IntegrationForm, {
      propsData: { ...props, formSelector: '.test' },
      store,
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
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findOverrideDropdown = () => wrapper.findComponent(OverrideDropdown);
  const findActiveCheckbox = () => wrapper.findComponent(ActiveCheckbox);
  const findConfirmationModal = () => wrapper.findComponent(ConfirmationModal);
  const findResetConfirmationModal = () => wrapper.findComponent(ResetConfirmationModal);
  const findResetButton = () => wrapper.findByTestId('reset-button');
  const findSaveButton = () => wrapper.findByTestId('save-button');
  const findTestButton = () => wrapper.findByTestId('test-button');
  const findJiraTriggerFields = () => wrapper.findComponent(JiraTriggerFields);
  const findJiraIssuesFields = () => wrapper.findComponent(JiraIssuesFields);
  const findTriggerFields = () => wrapper.findComponent(TriggerFields);

  describe('template', () => {
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
      beforeEach(() => {
        jest.spyOn(document, 'querySelector').mockReturnValue(document.createElement('form'));

        createComponent({
          customStateProps: { type: 'jira', testPath: '/test' },
        });
      });

      it('renders JiraTriggerFields', () => {
        expect(findJiraTriggerFields().exists()).toBe(true);
      });

      it('renders JiraIssuesFields', () => {
        expect(findJiraIssuesFields().exists()).toBe(true);
      });

      describe('when JiraIssueFields emits `request-jira-issue-types` event', () => {
        it('dispatches `requestJiraIssueTypes` action', () => {
          findJiraIssuesFields().vm.$emit('request-jira-issue-types');

          expect(dispatch).toHaveBeenCalledWith('requestJiraIssueTypes', expect.any(FormData));
        });
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
          <a data-confirm="Are you sure?" data-method="delete" href="/settings/slack"></a>
        </div>
      `);

      it('renders `helpHtml`', () => {
        const mockHelpHtml = document.querySelector(`[data-testid="${mockTestId}"]`);

        createComponent({
          props: {
            helpHtml: mockHelpHtml.outerHTML,
          },
        });

        const helpHtml = wrapper.findByTestId(mockTestId);
        const helpLink = helpHtml.find('a');

        expect(helpHtml.isVisible()).toBe(true);
        expect(helpHtml.find('svg').isVisible()).toBe(true);
        expect(helpLink.attributes()).toMatchObject({
          'data-confirm': 'Are you sure?',
          'data-method': 'delete',
        });
      });
    });
  });

  describe('ActiveCheckbox', () => {
    describe.each`
      showActive
      ${true}
      ${false}
    `('when `showActive` is $showActive', ({ showActive }) => {
      it(`${showActive ? 'renders' : 'does not render'} ActiveCheckbox`, () => {
        createComponent({
          customStateProps: {
            showActive,
          },
        });

        expect(findActiveCheckbox().exists()).toBe(showActive);
      });
    });

    describe.each`
      formActive | novalidate
      ${true}    | ${null}
      ${false}   | ${'true'}
    `(
      'when `toggle-integration-active` is emitted with $formActive',
      ({ formActive, novalidate }) => {
        let mockForm;

        beforeEach(async () => {
          mockForm = document.createElement('form');
          jest.spyOn(document, 'querySelector').mockReturnValue(mockForm);

          createComponent({
            customStateProps: {
              showActive: true,
              initialActivated: false,
            },
          });

          await findActiveCheckbox().vm.$emit('toggle-integration-active', formActive);
        });

        it(`sets noValidate to ${novalidate}`, () => {
          expect(mockForm.getAttribute('novalidate')).toBe(novalidate);
        });
      },
    );
  });

  describe('when `save` button is clicked', () => {
    let mockForm;

    describe.each`
      checkValidityReturn | integrationActive | formValid
      ${true}             | ${false}          | ${true}
      ${true}             | ${true}           | ${true}
      ${false}            | ${true}           | ${false}
      ${false}            | ${false}          | ${true}
    `(
      'when form checkValidity returns $checkValidityReturn and integrationActive is $integrationActive',
      ({ formValid, integrationActive, checkValidityReturn }) => {
        beforeEach(() => {
          mockForm = document.createElement('form');
          jest.spyOn(document, 'querySelector').mockReturnValue(mockForm);
          jest.spyOn(mockForm, 'checkValidity').mockReturnValue(checkValidityReturn);

          createComponent({
            customStateProps: {
              showActive: true,
              initialActivated: integrationActive,
            },
          });

          findSaveButton().vm.$emit('click', new Event('click'));
        });

        it('dispatches setIsSaving action', () => {
          expect(dispatch).toHaveBeenCalledWith('setIsSaving', true);
        });

        it(`emits \`SAVE_INTEGRATION_EVENT\` event with payload \`${formValid}\``, () => {
          expect(eventHub.$emit).toHaveBeenCalledWith(SAVE_INTEGRATION_EVENT, formValid);
        });
      },
    );
  });

  describe('when `test` button is clicked', () => {
    let mockForm;

    describe.each`
      formValid
      ${true}
      ${false}
    `('when form checkValidity returns $formValid', ({ formValid }) => {
      beforeEach(() => {
        mockForm = document.createElement('form');
        jest.spyOn(document, 'querySelector').mockReturnValue(mockForm);
        jest.spyOn(mockForm, 'checkValidity').mockReturnValue(formValid);

        createComponent({
          customStateProps: {
            showActive: true,
            canTest: true,
          },
        });

        findTestButton().vm.$emit('click', new Event('click'));
      });

      it('dispatches setIsTesting action', () => {
        expect(dispatch).toHaveBeenCalledWith('setIsTesting', true);
      });

      it(`emits \`TEST_INTEGRATION_EVENT\` event with payload \`${formValid}\``, () => {
        expect(eventHub.$emit).toHaveBeenCalledWith(TEST_INTEGRATION_EVENT, formValid);
      });
    });
  });
});
