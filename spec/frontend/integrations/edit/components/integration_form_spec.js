import { GlAlert, GlForm } from '@gitlab/ui';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { setHTMLFixture } from 'helpers/fixtures';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ActiveCheckbox from '~/integrations/edit/components/active_checkbox.vue';
import DynamicField from '~/integrations/edit/components/dynamic_field.vue';
import IntegrationForm from '~/integrations/edit/components/integration_form.vue';
import OverrideDropdown from '~/integrations/edit/components/override_dropdown.vue';
import TriggerFields from '~/integrations/edit/components/trigger_fields.vue';
import IntegrationFormActions from '~/integrations/edit/components/integration_form_actions.vue';
import IntegrationFormSection from '~/integrations/edit/components/integration_forms/section.vue';

import {
  I18N_SUCCESSFUL_CONNECTION_MESSAGE,
  I18N_DEFAULT_ERROR_MESSAGE,
  INTEGRATION_FORM_TYPE_SLACK,
  INTEGRATION_FORM_TYPE_GOOGLE_CLOUD_ARTIFACT_REGISTRY,
  INTEGRATION_FORM_TYPE_GOOGLE_CLOUD_IAM,
} from '~/integrations/constants';
import { createStore } from '~/integrations/edit/store';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import {
  mockIntegrationProps,
  mockField,
  mockSectionConnection,
  mockSectionJiraIssues,
} from '../mock_data';

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/lib/utils/url_utility');

describe('IntegrationForm', () => {
  const mockToastShow = jest.fn();

  let wrapper;
  let dispatch;
  let mockAxios;

  const createComponent = ({
    customStateProps = {},
    initialState = {},
    provide = {},
    mountFn = shallowMountExtended,
  } = {}) => {
    const store = createStore({
      customState: { ...mockIntegrationProps, ...customStateProps },
      ...initialState,
    });
    dispatch = jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = mountFn(IntegrationForm, {
      provide,
      store,
      stubs: {
        OverrideDropdown,
        ActiveCheckbox,
        TriggerFields,
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });
  };

  const findOverrideDropdown = () => wrapper.findComponent(OverrideDropdown);
  const findActiveCheckbox = () => wrapper.findComponent(ActiveCheckbox);
  const findTriggerFields = () => wrapper.findComponent(TriggerFields);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findGlForm = () => wrapper.findComponent(GlForm);
  const findRedirectToField = () => wrapper.findByTestId('redirect-to-field');
  const findDynamicField = () => wrapper.findComponent(DynamicField);
  const findAllDynamicFields = () => wrapper.findAllComponents(DynamicField);
  const findAllSections = () => wrapper.findAllComponents(IntegrationFormSection);
  const findHelpHtml = () => wrapper.findByTestId('help-html');
  const findFormActions = () => wrapper.findComponent(IntegrationFormActions);

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockAxios.restore();
  });

  describe('template', () => {
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
      it('renders DynamicField for each field without a section', () => {
        const sectionFields = [
          { name: 'username', type: 'text', section: mockSectionConnection.type },
          { name: 'API token', type: 'password', section: mockSectionConnection.type },
        ];

        const nonSectionFields = [
          { name: 'branch', type: 'text' },
          { name: 'labels', type: 'select' },
        ];

        createComponent({
          customStateProps: {
            sections: [mockSectionConnection],
            fields: [...sectionFields, ...nonSectionFields],
          },
        });

        const dynamicFields = findAllDynamicFields();

        expect(dynamicFields).toHaveLength(2);
        dynamicFields.wrappers.forEach((field, index) => {
          expect(field.props()).toMatchObject(nonSectionFields[index]);
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

    describe('with `helpHtml` provided', () => {
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
          provide: {
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

    it('renders hidden fields', () => {
      createComponent({
        customStateProps: {
          redirectTo: '/services',
        },
      });

      expect(findRedirectToField().attributes('value')).toBe('/services');
    });
  });

  describe('when integration has sections', () => {
    beforeEach(() => {
      createComponent({
        customStateProps: {
          sections: [mockSectionConnection, mockSectionJiraIssues],
        },
      });
    });

    it('renders the expected number of sections', () => {
      expect(findAllSections()).toHaveLength(2);
    });

    describe.each`
      formActive | method
      ${true}    | ${'toBeUndefined'}
      ${false}   | ${'toBeDefined'}
    `('when `toggle-integration-active` is emitted with $formActive', ({ formActive, method }) => {
      beforeEach(() => {
        createComponent({
          customStateProps: {
            sections: [mockSectionConnection],
            manualActivation: true,
            initialActivated: false,
          },
        });

        const section = findAllSections().at(0);
        section.vm.$emit('toggle-integration-active', formActive);
      });

      it(`checks noValidate ${method}`, () => {
        expect(findGlForm().attributes('novalidate'))[method]();
      });
    });

    describe('when section emits `request-jira-issue-types` event', () => {
      beforeEach(() => {
        jest.spyOn(document, 'querySelector').mockReturnValue(document.createElement('form'));

        createComponent({
          customStateProps: {
            sections: [mockSectionConnection],
            testPath: '/test',
          },
          mountFn: mountExtended,
        });

        const section = findAllSections().at(0);
        section.vm.$emit('request-jira-issue-types');
      });

      it('dispatches `requestJiraIssueTypes` action', () => {
        expect(dispatch).toHaveBeenCalledWith('requestJiraIssueTypes', expect.any(FormData));
      });
    });
  });

  describe('ActiveCheckbox', () => {
    describe.each`
      manualActivation
      ${true}
      ${false}
    `('when `manualActivation` is $manualActivation', ({ manualActivation }) => {
      it(`${manualActivation ? 'renders' : 'does not render'} ActiveCheckbox`, () => {
        createComponent({
          customStateProps: {
            manualActivation,
          },
        });

        expect(findActiveCheckbox().exists()).toBe(manualActivation);
      });
    });

    describe.each`
      formActive | method
      ${true}    | ${'toBeUndefined'}
      ${false}   | ${'toBeDefined'}
    `('when `toggle-integration-active` is emitted with $formActive', ({ formActive, method }) => {
      beforeEach(() => {
        createComponent({
          customStateProps: {
            manualActivation: true,
            initialActivated: false,
          },
        });

        findActiveCheckbox().vm.$emit('toggle-integration-active', formActive);
      });

      it(`checks noValidate ${method}`, () => {
        expect(findGlForm().attributes('novalidate'))[method]();
      });
    });
  });

  describe('Response to the "save" event (form submission)', () => {
    const prepareComponentAndSave = async (initialActivated = true, checkValidityReturn) => {
      createComponent({
        customStateProps: {
          manualActivation: true,
          initialActivated,
          fields: [mockField],
        },
        mountFn: mountExtended,
      });
      jest.spyOn(findGlForm().element, 'submit');
      jest.spyOn(findGlForm().element, 'checkValidity').mockReturnValue(checkValidityReturn);

      findFormActions().vm.$emit('save');
      await nextTick();
    };

    it.each`
      desc                 | checkValidityReturn | integrationActive | shouldSubmit
      ${'form is valid'}   | ${true}             | ${false}          | ${true}
      ${'form is valid'}   | ${true}             | ${true}           | ${true}
      ${'form is invalid'} | ${false}            | ${false}          | ${true}
      ${'form is invalid'} | ${false}            | ${true}           | ${false}
    `(
      'when $desc (checkValidity returns $checkValidityReturn and integrationActive is $integrationActive)',
      async ({ integrationActive, checkValidityReturn, shouldSubmit }) => {
        await prepareComponentAndSave(integrationActive, checkValidityReturn);

        if (shouldSubmit) {
          expect(findGlForm().element.submit).toHaveBeenCalledTimes(1);
        } else {
          expect(findGlForm().element.submit).not.toHaveBeenCalled();
        }
      },
    );

    it('flips `isSaving` to `true`', async () => {
      await prepareComponentAndSave(true, true);
      expect(findFormActions().props('isSaving')).toBe(true);
    });

    describe('when form is invalid', () => {
      beforeEach(async () => {
        await prepareComponentAndSave(true, false);
      });

      it('when form is invalid, it sets `isValidated` props on form fields', () => {
        expect(findDynamicField().props('isValidated')).toBe(true);
      });

      it('resets `isSaving`', () => {
        expect(findFormActions().props('isSaving')).toBe(false);
      });
    });
  });

  describe('Response to the "test" event from the actions', () => {
    describe('when form is invalid', () => {
      beforeEach(async () => {
        createComponent({
          customStateProps: {
            manualActivation: true,
            fields: [mockField],
          },
          mountFn: mountExtended,
        });
        jest.spyOn(findGlForm().element, 'checkValidity').mockReturnValue(false);

        findFormActions().vm.$emit('test');
        await nextTick();
      });

      it('sets `isValidated` props on form fields', () => {
        expect(findDynamicField().props('isValidated')).toBe(true);
      });

      it('resets `isTesting`', () => {
        expect(findFormActions().props('isTesting')).toBe(false);
      });
    });

    describe('when form is valid', () => {
      const mockTestPath = '/test';

      beforeEach(() => {
        createComponent({
          customStateProps: {
            manualActivation: true,
            testPath: mockTestPath,
          },
          mountFn: mountExtended,
        });

        jest.spyOn(findGlForm().element, 'checkValidity').mockReturnValue(true);
      });

      it('flips `isTesting` to `true`', async () => {
        findFormActions().vm.$emit('test');
        await nextTick();
        expect(findFormActions().props('isTesting')).toBe(true);
      });

      describe.each`
        scenario                                                | replyStatus                          | errorMessage   | serviceResponse | expectToast                           | expectSentry
        ${'when "test settings" request fails'}                 | ${HTTP_STATUS_INTERNAL_SERVER_ERROR} | ${undefined}   | ${undefined}    | ${I18N_DEFAULT_ERROR_MESSAGE}         | ${true}
        ${'when "test settings" returns an error'}              | ${HTTP_STATUS_OK}                    | ${'an error'}  | ${undefined}    | ${'an error'}                         | ${false}
        ${'when "test settings" returns an error with details'} | ${HTTP_STATUS_OK}                    | ${'an error.'} | ${'extra info'} | ${'an error. extra info'}             | ${false}
        ${'when "test settings" succeeds'}                      | ${HTTP_STATUS_OK}                    | ${undefined}   | ${undefined}    | ${I18N_SUCCESSFUL_CONNECTION_MESSAGE} | ${false}
      `(
        '$scenario',
        ({ replyStatus, errorMessage, serviceResponse, expectToast, expectSentry }) => {
          beforeEach(async () => {
            mockAxios.onPut(mockTestPath).replyOnce(replyStatus, {
              error: Boolean(errorMessage),
              message: errorMessage,
              service_response: serviceResponse,
            });

            findFormActions().vm.$emit('test');
            await waitForPromises();
          });

          it(`calls toast with '${expectToast}'`, () => {
            expect(mockToastShow).toHaveBeenCalledWith(expectToast);
          });

          it(`${expectSentry ? 'does' : 'does not'} capture exception in Sentry`, () => {
            expect(Sentry.captureException).toHaveBeenCalledTimes(expectSentry ? 1 : 0);
          });
        },
      );
    });
  });

  describe('Response to the "reset" event from the actions', () => {
    const mockResetPath = '/reset';

    beforeEach(async () => {
      mockAxios.onPost(mockResetPath).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      createComponent({
        customStateProps: {
          resetPath: mockResetPath,
        },
      });

      findFormActions().vm.$emit('reset');
      await nextTick();
    });

    it('flips `isResetting` to `true`', () => {
      expect(findFormActions().props('isResetting')).toBe(true);
    });

    describe('when "reset settings" request fails', () => {
      beforeEach(async () => {
        await waitForPromises();
      });

      it('displays a toast', () => {
        expect(mockToastShow).toHaveBeenCalledWith(I18N_DEFAULT_ERROR_MESSAGE);
      });

      it('captures exception in Sentry', () => {
        expect(Sentry.captureException).toHaveBeenCalledTimes(1);
      });

      it('resets `isResetting`', () => {
        expect(findFormActions().props('isResetting')).toBe(false);
      });
    });

    describe('when "reset settings" succeeds', () => {
      beforeEach(async () => {
        mockAxios.onPost(mockResetPath).replyOnce(HTTP_STATUS_OK);
        createComponent({
          customStateProps: {
            resetPath: mockResetPath,
          },
        });

        findFormActions().vm.$emit('reset');
        await waitForPromises();
      });

      it('calls `refreshCurrentPage`', () => {
        expect(refreshCurrentPage).toHaveBeenCalledTimes(1);
      });

      it('resets `isResetting`', () => {
        expect(findFormActions().props('isResetting')).toBe(false);
      });
    });
  });

  describe('Slack integration', () => {
    describe('Help and sections rendering', () => {
      const dummyHelp = 'Foo Help';

      it.each`
        integration                    | helpHtml     | sections                   | shouldShowSections | shouldShowHelp
        ${INTEGRATION_FORM_TYPE_SLACK} | ${''}        | ${[]}                      | ${false}           | ${false}
        ${INTEGRATION_FORM_TYPE_SLACK} | ${dummyHelp} | ${[]}                      | ${false}           | ${true}
        ${INTEGRATION_FORM_TYPE_SLACK} | ${undefined} | ${[mockSectionConnection]} | ${true}            | ${false}
        ${INTEGRATION_FORM_TYPE_SLACK} | ${dummyHelp} | ${[mockSectionConnection]} | ${true}            | ${true}
        ${'foo'}                       | ${''}        | ${[]}                      | ${false}           | ${false}
        ${'foo'}                       | ${dummyHelp} | ${[]}                      | ${false}           | ${true}
        ${'foo'}                       | ${undefined} | ${[mockSectionConnection]} | ${true}            | ${false}
        ${'foo'}                       | ${dummyHelp} | ${[mockSectionConnection]} | ${true}            | ${false}
      `(
        '$sections sections, and "$helpHtml" helpHtml for "$integration" integration',
        ({ integration, helpHtml, sections, shouldShowSections, shouldShowHelp }) => {
          createComponent({
            provide: {
              helpHtml,
            },
            customStateProps: {
              sections,
              type: integration,
            },
          });
          expect(findAllSections().length > 0).toEqual(shouldShowSections);
          expect(findHelpHtml().exists()).toBe(shouldShowHelp);
          if (shouldShowHelp) {
            expect(findHelpHtml().html()).toContain(helpHtml);
          }
        },
      );
    });

    describe.each`
      hasSections | hasFieldsWithoutSections | description
      ${true}     | ${true}                  | ${'When having both: the sections and the fields without a section'}
      ${true}     | ${false}                 | ${'When having the sections only'}
      ${false}    | ${true}                  | ${'When having only the fields without a section'}
    `('$description', ({ hasSections, hasFieldsWithoutSections }) => {
      it.each`
        prefix        | integration                    | shouldUpgradeSlack | shouldShowAlert
        ${'does'}     | ${INTEGRATION_FORM_TYPE_SLACK} | ${true}            | ${true}
        ${'does not'} | ${INTEGRATION_FORM_TYPE_SLACK} | ${false}           | ${false}
        ${'does not'} | ${'foo'}                       | ${true}            | ${false}
        ${'does not'} | ${'foo'}                       | ${false}           | ${false}
      `(
        '$prefix render the upgrade warning when we are in "$integration" integration with Slack-needs-upgrade is "$shouldUpgradeSlack" and have sections',
        ({ integration, shouldUpgradeSlack, shouldShowAlert }) => {
          createComponent({
            customStateProps: {
              shouldUpgradeSlack,
              type: integration,
              sections: hasSections ? [mockSectionConnection] : [],
              fields: hasFieldsWithoutSections ? [mockField] : [],
            },
          });
          expect(findAlert().exists()).toBe(shouldShowAlert);
        },
      );
    });
  });

  describe('Google Artifact Management integration', () => {
    describe('Help and sections rendering', () => {
      const dummyHelp = 'Foo Help';

      it.each`
        integration                                             | helpHtml     | sections                   | shouldShowSections | shouldShowHelp
        ${INTEGRATION_FORM_TYPE_GOOGLE_CLOUD_ARTIFACT_REGISTRY} | ${''}        | ${[]}                      | ${false}           | ${false}
        ${INTEGRATION_FORM_TYPE_GOOGLE_CLOUD_ARTIFACT_REGISTRY} | ${dummyHelp} | ${[]}                      | ${false}           | ${true}
        ${INTEGRATION_FORM_TYPE_GOOGLE_CLOUD_ARTIFACT_REGISTRY} | ${undefined} | ${[mockSectionConnection]} | ${true}            | ${false}
        ${INTEGRATION_FORM_TYPE_GOOGLE_CLOUD_ARTIFACT_REGISTRY} | ${dummyHelp} | ${[mockSectionConnection]} | ${true}            | ${true}
        ${'foo'}                                                | ${''}        | ${[]}                      | ${false}           | ${false}
        ${'foo'}                                                | ${dummyHelp} | ${[]}                      | ${false}           | ${true}
        ${'foo'}                                                | ${undefined} | ${[mockSectionConnection]} | ${true}            | ${false}
        ${'foo'}                                                | ${dummyHelp} | ${[mockSectionConnection]} | ${true}            | ${false}
      `(
        '$sections sections, and "$helpHtml" helpHtml for "$integration" integration',
        ({ integration, helpHtml, sections, shouldShowSections, shouldShowHelp }) => {
          createComponent({
            provide: {
              helpHtml,
            },
            customStateProps: {
              sections,
              type: integration,
            },
          });
          expect(findAllSections().length > 0).toEqual(shouldShowSections);
          expect(findHelpHtml().exists()).toBe(shouldShowHelp);
          if (shouldShowHelp) {
            expect(findHelpHtml().html()).toContain(helpHtml);
          }
        },
      );
    });
  });

  describe('Google Cloud IAM', () => {
    const helpHtml = 'Foo Help';

    beforeEach(() => {
      createComponent({
        provide: { helpHtml },
        customStateProps: {
          sections: [mockSectionConnection],
          type: INTEGRATION_FORM_TYPE_GOOGLE_CLOUD_IAM,
        },
      });
    });

    it('show help text', () => {
      expect(findHelpHtml().text()).toBe(helpHtml);
    });

    it('show section', () => {
      expect(findAllSections()).toHaveLength(1);
    });
  });
});
