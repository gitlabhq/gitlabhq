import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import * as Sentry from '@sentry/browser';
import { setHTMLFixture } from 'helpers/fixtures';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
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
  I18N_SUCCESSFUL_CONNECTION_MESSAGE,
  VALIDATE_INTEGRATION_FORM_EVENT,
  I18N_DEFAULT_ERROR_MESSAGE,
} from '~/integrations/constants';
import { createStore } from '~/integrations/edit/store';
import eventHub from '~/integrations/edit/event_hub';
import httpStatus from '~/lib/utils/http_status';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import { mockIntegrationProps } from '../mock_data';

jest.mock('~/integrations/edit/event_hub');
jest.mock('@sentry/browser');
jest.mock('~/lib/utils/url_utility');

describe('IntegrationForm', () => {
  const mockToastShow = jest.fn();

  let wrapper;
  let dispatch;
  let mockAxios;
  let mockForm;

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
      provide: {
        glFeatures: featureFlags,
      },
      store,
      stubs: {
        OverrideDropdown,
        ActiveCheckbox,
        ConfirmationModal,
        JiraTriggerFields,
        TriggerFields,
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });
  };

  const createForm = ({ isValid = true } = {}) => {
    mockForm = document.createElement('form');
    jest.spyOn(document, 'querySelector').mockReturnValue(mockForm);
    jest.spyOn(mockForm, 'checkValidity').mockReturnValue(isValid);
    jest.spyOn(mockForm, 'submit');
  };

  const findOverrideDropdown = () => wrapper.findComponent(OverrideDropdown);
  const findActiveCheckbox = () => wrapper.findComponent(ActiveCheckbox);
  const findConfirmationModal = () => wrapper.findComponent(ConfirmationModal);
  const findResetConfirmationModal = () => wrapper.findComponent(ResetConfirmationModal);
  const findResetButton = () => wrapper.findByTestId('reset-button');
  const findProjectSaveButton = () => wrapper.findByTestId('save-button');
  const findInstanceOrGroupSaveButton = () => wrapper.findByTestId('save-button-instance-group');
  const findTestButton = () => wrapper.findByTestId('test-button');
  const findJiraTriggerFields = () => wrapper.findComponent(JiraTriggerFields);
  const findJiraIssuesFields = () => wrapper.findComponent(JiraIssuesFields);
  const findTriggerFields = () => wrapper.findComponent(TriggerFields);

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    mockAxios.restore();
  });

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
        beforeEach(async () => {
          createForm();
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
    describe('buttons', () => {
      beforeEach(async () => {
        createForm();
        createComponent({
          customStateProps: {
            showActive: true,
            canTest: true,
            initialActivated: true,
          },
        });

        await findProjectSaveButton().vm.$emit('click', new Event('click'));
      });

      it('sets save button `loading` prop to `true`', () => {
        expect(findProjectSaveButton().props('loading')).toBe(true);
      });

      it('sets test button `disabled` prop to `true`', () => {
        expect(findTestButton().props('disabled')).toBe(true);
      });
    });

    describe.each`
      checkValidityReturn | integrationActive
      ${true}             | ${false}
      ${true}             | ${true}
      ${false}            | ${false}
    `(
      'when form is valid (checkValidity returns $checkValidityReturn and integrationActive is $integrationActive)',
      ({ integrationActive, checkValidityReturn }) => {
        beforeEach(async () => {
          createForm({ isValid: checkValidityReturn });
          createComponent({
            customStateProps: {
              showActive: true,
              canTest: true,
              initialActivated: integrationActive,
            },
          });

          await findProjectSaveButton().vm.$emit('click', new Event('click'));
        });

        it('submit form', () => {
          expect(mockForm.submit).toHaveBeenCalledTimes(1);
        });
      },
    );

    describe('when form is invalid (checkValidity returns false and integrationActive is true)', () => {
      beforeEach(async () => {
        createForm({ isValid: false });
        createComponent({
          customStateProps: {
            showActive: true,
            canTest: true,
            initialActivated: true,
          },
        });

        await findProjectSaveButton().vm.$emit('click', new Event('click'));
      });

      it('does not submit form', () => {
        expect(mockForm.submit).not.toHaveBeenCalled();
      });

      it('sets save button `loading` prop to `false`', () => {
        expect(findProjectSaveButton().props('loading')).toBe(false);
      });

      it('sets test button `disabled` prop to `false`', () => {
        expect(findTestButton().props('disabled')).toBe(false);
      });

      it('emits `VALIDATE_INTEGRATION_FORM_EVENT`', () => {
        expect(eventHub.$emit).toHaveBeenCalledWith(VALIDATE_INTEGRATION_FORM_EVENT);
      });
    });
  });

  describe('when `test` button is clicked', () => {
    describe('when form is invalid', () => {
      it('emits `VALIDATE_INTEGRATION_FORM_EVENT` event to the event hub', () => {
        createForm({ isValid: false });
        createComponent({
          customStateProps: {
            showActive: true,
            canTest: true,
          },
        });

        findTestButton().vm.$emit('click', new Event('click'));

        expect(eventHub.$emit).toHaveBeenCalledWith(VALIDATE_INTEGRATION_FORM_EVENT);
      });
    });

    describe('when form is valid', () => {
      const mockTestPath = '/test';

      beforeEach(() => {
        createForm({ isValid: true });
        createComponent({
          customStateProps: {
            showActive: true,
            canTest: true,
            testPath: mockTestPath,
          },
        });
      });

      describe('buttons', () => {
        beforeEach(async () => {
          await findTestButton().vm.$emit('click', new Event('click'));
        });

        it('sets test button `loading` prop to `true`', () => {
          expect(findTestButton().props('loading')).toBe(true);
        });

        it('sets save button `disabled` prop to `true`', () => {
          expect(findProjectSaveButton().props('disabled')).toBe(true);
        });
      });

      describe.each`
        scenario                                   | replyStatus                         | errorMessage  | expectToast                           | expectSentry
        ${'when "test settings" request fails'}    | ${httpStatus.INTERNAL_SERVER_ERROR} | ${undefined}  | ${I18N_DEFAULT_ERROR_MESSAGE}         | ${true}
        ${'when "test settings" returns an error'} | ${httpStatus.OK}                    | ${'an error'} | ${'an error'}                         | ${false}
        ${'when "test settings" succeeds'}         | ${httpStatus.OK}                    | ${undefined}  | ${I18N_SUCCESSFUL_CONNECTION_MESSAGE} | ${false}
      `('$scenario', ({ replyStatus, errorMessage, expectToast, expectSentry }) => {
        beforeEach(async () => {
          mockAxios.onPut(mockTestPath).replyOnce(replyStatus, {
            error: Boolean(errorMessage),
            message: errorMessage,
          });

          await findTestButton().vm.$emit('click', new Event('click'));
          await waitForPromises();
        });

        it(`calls toast with '${expectToast}'`, () => {
          expect(mockToastShow).toHaveBeenCalledWith(expectToast);
        });

        it('sets `loading` prop of test button to `false`', () => {
          expect(findTestButton().props('loading')).toBe(false);
        });

        it('sets save button `disabled` prop to `false`', () => {
          expect(findProjectSaveButton().props('disabled')).toBe(false);
        });

        it(`${expectSentry ? 'does' : 'does not'} capture exception in Sentry`, () => {
          expect(Sentry.captureException).toHaveBeenCalledTimes(expectSentry ? 1 : 0);
        });
      });
    });
  });

  describe('when `reset-confirmation-modal` emits `reset` event', () => {
    const mockResetPath = '/reset';

    describe('buttons', () => {
      beforeEach(async () => {
        createComponent({
          customStateProps: {
            integrationLevel: integrationLevels.GROUP,
            canTest: true,
            resetPath: mockResetPath,
          },
        });

        await findResetConfirmationModal().vm.$emit('reset');
      });

      it('sets reset button `loading` prop to `true`', () => {
        expect(findResetButton().props('loading')).toBe(true);
      });

      it('sets other button `disabled` props to `true`', () => {
        expect(findInstanceOrGroupSaveButton().props('disabled')).toBe(true);
        expect(findTestButton().props('disabled')).toBe(true);
      });
    });

    describe('when "reset settings" request fails', () => {
      beforeEach(async () => {
        mockAxios.onPost(mockResetPath).replyOnce(httpStatus.INTERNAL_SERVER_ERROR);
        createComponent({
          customStateProps: {
            integrationLevel: integrationLevels.GROUP,
            canTest: true,
            resetPath: mockResetPath,
          },
        });

        await findResetConfirmationModal().vm.$emit('reset');
        await waitForPromises();
      });

      it('displays a toast', () => {
        expect(mockToastShow).toHaveBeenCalledWith(I18N_DEFAULT_ERROR_MESSAGE);
      });

      it('captures exception in Sentry', () => {
        expect(Sentry.captureException).toHaveBeenCalledTimes(1);
      });

      it('sets reset button `loading` prop to `false`', () => {
        expect(findResetButton().props('loading')).toBe(false);
      });

      it('sets button `disabled` props to `false`', () => {
        expect(findInstanceOrGroupSaveButton().props('disabled')).toBe(false);
        expect(findTestButton().props('disabled')).toBe(false);
      });
    });

    describe('when "reset settings" succeeds', () => {
      beforeEach(async () => {
        mockAxios.onPost(mockResetPath).replyOnce(httpStatus.OK);
        createComponent({
          customStateProps: {
            integrationLevel: integrationLevels.GROUP,
            resetPath: mockResetPath,
          },
        });

        await findResetConfirmationModal().vm.$emit('reset');
        await waitForPromises();
      });

      it('calls `refreshCurrentPage`', () => {
        expect(refreshCurrentPage).toHaveBeenCalledTimes(1);
      });
    });
  });
});
