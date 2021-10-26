import MockAdaptor from 'axios-mock-adapter';
import IntegrationSettingsForm from '~/integrations/integration_settings_form';
import eventHub from '~/integrations/edit/event_hub';
import axios from '~/lib/utils/axios_utils';
import toast from '~/vue_shared/plugins/global_toast';
import {
  I18N_FETCH_TEST_SETTINGS_DEFAULT_ERROR_MESSAGE,
  I18N_SUCCESSFUL_CONNECTION_MESSAGE,
  I18N_DEFAULT_ERROR_MESSAGE,
  GET_JIRA_ISSUE_TYPES_EVENT,
  TOGGLE_INTEGRATION_EVENT,
  TEST_INTEGRATION_EVENT,
  SAVE_INTEGRATION_EVENT,
} from '~/integrations/constants';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/vue_shared/plugins/global_toast');
jest.mock('lodash/delay', () => (callback) => callback());

const FIXTURE = 'services/edit_service.html';

describe('IntegrationSettingsForm', () => {
  let integrationSettingsForm;

  const mockStoreDispatch = () => jest.spyOn(integrationSettingsForm.vue.$store, 'dispatch');

  beforeEach(() => {
    loadFixtures(FIXTURE);

    integrationSettingsForm = new IntegrationSettingsForm('.js-integration-settings-form');
    integrationSettingsForm.init();
  });

  describe('constructor', () => {
    it('should initialize form element refs on class object', () => {
      expect(integrationSettingsForm.$form).toBeDefined();
      expect(integrationSettingsForm.$form.nodeName).toBe('FORM');
      expect(integrationSettingsForm.formActive).toBeDefined();
    });

    it('should initialize form metadata on class object', () => {
      expect(integrationSettingsForm.testEndPoint).toBeDefined();
    });
  });

  describe('event handling', () => {
    let mockAxios;

    beforeEach(() => {
      mockAxios = new MockAdaptor(axios);
      jest.spyOn(axios, 'put');
    });

    afterEach(() => {
      mockAxios.restore();
      eventHub.dispose(); // clear event hub handlers
    });

    describe('when event hub receives `TOGGLE_INTEGRATION_EVENT`', () => {
      it('should remove `novalidate` attribute to form when called with `true`', () => {
        eventHub.$emit(TOGGLE_INTEGRATION_EVENT, true);

        expect(integrationSettingsForm.$form.getAttribute('novalidate')).toBe(null);
      });

      it('should set `novalidate` attribute to form when called with `false`', () => {
        eventHub.$emit(TOGGLE_INTEGRATION_EVENT, false);

        expect(integrationSettingsForm.$form.getAttribute('novalidate')).toBe('novalidate');
      });
    });

    describe('when event hub receives `TEST_INTEGRATION_EVENT`', () => {
      describe('when form is valid', () => {
        beforeEach(() => {
          jest.spyOn(integrationSettingsForm.$form, 'checkValidity').mockReturnValue(true);
        });

        it('should make an ajax request with provided `formData`', async () => {
          eventHub.$emit(TEST_INTEGRATION_EVENT);
          await waitForPromises();

          expect(axios.put).toHaveBeenCalledWith(
            integrationSettingsForm.testEndPoint,
            new FormData(integrationSettingsForm.$form),
          );
        });

        it('should show success message if test is successful', async () => {
          jest.spyOn(integrationSettingsForm.$form, 'submit').mockImplementation(() => {});

          mockAxios.onPut(integrationSettingsForm.testEndPoint).reply(200, {
            error: false,
          });

          eventHub.$emit(TEST_INTEGRATION_EVENT);
          await waitForPromises();

          expect(toast).toHaveBeenCalledWith(I18N_SUCCESSFUL_CONNECTION_MESSAGE);
        });

        it('should show error message if ajax request responds with test error', async () => {
          const errorMessage = 'Test failed.';
          const serviceResponse = 'some error';

          mockAxios.onPut(integrationSettingsForm.testEndPoint).reply(200, {
            error: true,
            message: errorMessage,
            service_response: serviceResponse,
            test_failed: false,
          });

          eventHub.$emit(TEST_INTEGRATION_EVENT);
          await waitForPromises();

          expect(toast).toHaveBeenCalledWith(`${errorMessage} ${serviceResponse}`);
        });

        it('should show error message if ajax request failed', async () => {
          mockAxios.onPut(integrationSettingsForm.testEndPoint).networkError();

          eventHub.$emit(TEST_INTEGRATION_EVENT);
          await waitForPromises();

          expect(toast).toHaveBeenCalledWith(I18N_DEFAULT_ERROR_MESSAGE);
        });

        it('should always dispatch `setIsTesting` with `false` once request is completed', async () => {
          const dispatchSpy = mockStoreDispatch();
          mockAxios.onPut(integrationSettingsForm.testEndPoint).networkError();

          eventHub.$emit(TEST_INTEGRATION_EVENT);
          await waitForPromises();

          expect(dispatchSpy).toHaveBeenCalledWith('setIsTesting', false);
        });
      });

      describe('when form is invalid', () => {
        beforeEach(() => {
          jest.spyOn(integrationSettingsForm.$form, 'checkValidity').mockReturnValue(false);
          jest.spyOn(integrationSettingsForm, 'testSettings');
        });

        it('should dispatch `setIsTesting` with `false` and not call `testSettings`', async () => {
          const dispatchSpy = mockStoreDispatch();

          eventHub.$emit(TEST_INTEGRATION_EVENT);
          await waitForPromises();

          expect(dispatchSpy).toHaveBeenCalledWith('setIsTesting', false);
          expect(integrationSettingsForm.testSettings).not.toHaveBeenCalled();
        });
      });
    });

    describe('when event hub receives `GET_JIRA_ISSUE_TYPES_EVENT`', () => {
      it('should always dispatch `requestJiraIssueTypes`', () => {
        const dispatchSpy = mockStoreDispatch();
        mockAxios.onPut(integrationSettingsForm.testEndPoint).networkError();

        eventHub.$emit(GET_JIRA_ISSUE_TYPES_EVENT);

        expect(dispatchSpy).toHaveBeenCalledWith('requestJiraIssueTypes');
      });

      it('should make an ajax request with provided `formData`', () => {
        eventHub.$emit(GET_JIRA_ISSUE_TYPES_EVENT);

        expect(axios.put).toHaveBeenCalledWith(
          integrationSettingsForm.testEndPoint,
          new FormData(integrationSettingsForm.$form),
        );
      });

      it('should dispatch `receiveJiraIssueTypesSuccess` with the correct payload if ajax request is successful', async () => {
        const dispatchSpy = mockStoreDispatch();
        const mockData = ['ISSUE', 'EPIC'];
        mockAxios.onPut(integrationSettingsForm.testEndPoint).reply(200, {
          error: false,
          issuetypes: mockData,
        });

        eventHub.$emit(GET_JIRA_ISSUE_TYPES_EVENT);
        await waitForPromises();

        expect(dispatchSpy).toHaveBeenCalledWith('receiveJiraIssueTypesSuccess', mockData);
      });

      it.each(['Custom error message here', undefined])(
        'should dispatch "receiveJiraIssueTypesError" with a message if the backend responds with error',
        async (responseErrorMessage) => {
          const dispatchSpy = mockStoreDispatch();

          const expectedErrorMessage =
            responseErrorMessage || I18N_FETCH_TEST_SETTINGS_DEFAULT_ERROR_MESSAGE;
          mockAxios.onPut(integrationSettingsForm.testEndPoint).reply(200, {
            error: true,
            message: responseErrorMessage,
          });

          eventHub.$emit(GET_JIRA_ISSUE_TYPES_EVENT);
          await waitForPromises();

          expect(dispatchSpy).toHaveBeenCalledWith(
            'receiveJiraIssueTypesError',
            expectedErrorMessage,
          );
        },
      );
    });

    describe('when event hub receives `SAVE_INTEGRATION_EVENT`', () => {
      describe('when form is valid', () => {
        beforeEach(() => {
          jest.spyOn(integrationSettingsForm.$form, 'checkValidity').mockReturnValue(true);
          jest.spyOn(integrationSettingsForm.$form, 'submit');
        });

        it('should submit the form', async () => {
          eventHub.$emit(SAVE_INTEGRATION_EVENT);
          await waitForPromises();

          expect(integrationSettingsForm.$form.submit).toHaveBeenCalled();
          expect(integrationSettingsForm.$form.submit).toHaveBeenCalledTimes(1);
        });
      });

      describe('when form is invalid', () => {
        beforeEach(() => {
          jest.spyOn(integrationSettingsForm.$form, 'checkValidity').mockReturnValue(false);
          jest.spyOn(integrationSettingsForm.$form, 'submit');
        });

        it('should dispatch `setIsSaving` with `false` and not submit form', async () => {
          const dispatchSpy = mockStoreDispatch();

          eventHub.$emit(SAVE_INTEGRATION_EVENT);

          await waitForPromises();

          expect(dispatchSpy).toHaveBeenCalledWith('setIsSaving', false);
          expect(integrationSettingsForm.$form.submit).not.toHaveBeenCalled();
        });
      });
    });
  });
});
