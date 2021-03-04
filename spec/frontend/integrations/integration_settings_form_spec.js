import MockAdaptor from 'axios-mock-adapter';
import IntegrationSettingsForm from '~/integrations/integration_settings_form';
import axios from '~/lib/utils/axios_utils';
import toast from '~/vue_shared/plugins/global_toast';

jest.mock('~/vue_shared/plugins/global_toast');

describe('IntegrationSettingsForm', () => {
  const FIXTURE = 'services/edit_service.html';

  beforeEach(() => {
    loadFixtures(FIXTURE);
  });

  describe('constructor', () => {
    let integrationSettingsForm;

    beforeEach(() => {
      integrationSettingsForm = new IntegrationSettingsForm('.js-integration-settings-form');
      jest.spyOn(integrationSettingsForm, 'init').mockImplementation(() => {});
    });

    it('should initialize form element refs on class object', () => {
      // Form Reference
      expect(integrationSettingsForm.$form).toBeDefined();
      expect(integrationSettingsForm.$form.prop('nodeName')).toEqual('FORM');
      expect(integrationSettingsForm.formActive).toBeDefined();
    });

    it('should initialize form metadata on class object', () => {
      expect(integrationSettingsForm.testEndPoint).toBeDefined();
    });
  });

  describe('toggleServiceState', () => {
    let integrationSettingsForm;

    beforeEach(() => {
      integrationSettingsForm = new IntegrationSettingsForm('.js-integration-settings-form');
    });

    it('should remove `novalidate` attribute to form when called with `true`', () => {
      integrationSettingsForm.formActive = true;
      integrationSettingsForm.toggleServiceState();

      expect(integrationSettingsForm.$form.attr('novalidate')).not.toBeDefined();
    });

    it('should set `novalidate` attribute to form when called with `false`', () => {
      integrationSettingsForm.formActive = false;
      integrationSettingsForm.toggleServiceState();

      expect(integrationSettingsForm.$form.attr('novalidate')).toBeDefined();
    });
  });

  describe('testSettings', () => {
    let integrationSettingsForm;
    let formData;
    let mock;

    beforeEach(() => {
      mock = new MockAdaptor(axios);

      jest.spyOn(axios, 'put');

      integrationSettingsForm = new IntegrationSettingsForm('.js-integration-settings-form');
      integrationSettingsForm.init();

      // eslint-disable-next-line no-jquery/no-serialize
      formData = integrationSettingsForm.$form.serialize();
    });

    afterEach(() => {
      mock.restore();
    });

    it('should make an ajax request with provided `formData`', async () => {
      await integrationSettingsForm.testSettings(formData);

      expect(axios.put).toHaveBeenCalledWith(integrationSettingsForm.testEndPoint, formData);
    });

    it('should show success message if test is successful', async () => {
      jest.spyOn(integrationSettingsForm.$form, 'submit').mockImplementation(() => {});

      mock.onPut(integrationSettingsForm.testEndPoint).reply(200, {
        error: false,
      });

      await integrationSettingsForm.testSettings(formData);

      expect(toast).toHaveBeenCalledWith('Connection successful.');
    });

    it('should show error message if ajax request responds with test error', async () => {
      const errorMessage = 'Test failed.';
      const serviceResponse = 'some error';

      mock.onPut(integrationSettingsForm.testEndPoint).reply(200, {
        error: true,
        message: errorMessage,
        service_response: serviceResponse,
        test_failed: false,
      });

      await integrationSettingsForm.testSettings(formData);

      expect(toast).toHaveBeenCalledWith(`${errorMessage} ${serviceResponse}`);
    });

    it('should show error message if ajax request failed', async () => {
      const errorMessage = 'Something went wrong on our end.';

      mock.onPut(integrationSettingsForm.testEndPoint).networkError();

      await integrationSettingsForm.testSettings(formData);

      expect(toast).toHaveBeenCalledWith(errorMessage);
    });

    it('should always dispatch `setIsTesting` with `false` once request is completed', async () => {
      const dispatchSpy = jest.fn();

      mock.onPut(integrationSettingsForm.testEndPoint).networkError();

      integrationSettingsForm.vue.$store = { dispatch: dispatchSpy };

      await integrationSettingsForm.testSettings(formData);

      expect(dispatchSpy).toHaveBeenCalledWith('setIsTesting', false);
    });
  });

  describe('getJiraIssueTypes', () => {
    let integrationSettingsForm;
    let formData;
    let mock;

    beforeEach(() => {
      mock = new MockAdaptor(axios);

      jest.spyOn(axios, 'put');

      integrationSettingsForm = new IntegrationSettingsForm('.js-integration-settings-form');
      integrationSettingsForm.init();

      // eslint-disable-next-line no-jquery/no-serialize
      formData = integrationSettingsForm.$form.serialize();
    });

    afterEach(() => {
      mock.restore();
    });

    it('should always dispatch `requestJiraIssueTypes`', async () => {
      const dispatchSpy = jest.fn();

      mock.onPut(integrationSettingsForm.testEndPoint).networkError();

      integrationSettingsForm.vue.$store = { dispatch: dispatchSpy };

      await integrationSettingsForm.getJiraIssueTypes();

      expect(dispatchSpy).toHaveBeenCalledWith('requestJiraIssueTypes');
    });

    it('should make an ajax request with provided `formData`', async () => {
      await integrationSettingsForm.getJiraIssueTypes(formData);

      expect(axios.put).toHaveBeenCalledWith(integrationSettingsForm.testEndPoint, formData);
    });

    it('should dispatch `receiveJiraIssueTypesSuccess` with the correct payload if ajax request is successful', async () => {
      const mockData = ['ISSUE', 'EPIC'];
      const dispatchSpy = jest.fn();

      mock.onPut(integrationSettingsForm.testEndPoint).reply(200, {
        error: false,
        issuetypes: mockData,
      });

      integrationSettingsForm.vue.$store = { dispatch: dispatchSpy };

      await integrationSettingsForm.getJiraIssueTypes(formData);

      expect(dispatchSpy).toHaveBeenCalledWith('receiveJiraIssueTypesSuccess', mockData);
    });

    it.each(['something went wrong', undefined])(
      'should dispatch "receiveJiraIssueTypesError" with a message if the backend responds with error',
      async (responseErrorMessage) => {
        const defaultErrorMessage = 'Connection failed. Please check your settings.';
        const expectedErrorMessage = responseErrorMessage || defaultErrorMessage;
        const dispatchSpy = jest.fn();

        mock.onPut(integrationSettingsForm.testEndPoint).reply(200, {
          error: true,
          message: responseErrorMessage,
        });

        integrationSettingsForm.vue.$store = { dispatch: dispatchSpy };

        await integrationSettingsForm.getJiraIssueTypes(formData);

        expect(dispatchSpy).toHaveBeenCalledWith(
          'receiveJiraIssueTypesError',
          expectedErrorMessage,
        );
      },
    );
  });
});
