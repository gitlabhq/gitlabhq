import MockAdaptor from 'axios-mock-adapter';
import IntegrationSettingsForm from '~/integrations/integration_settings_form';
import eventHub from '~/integrations/edit/event_hub';
import axios from '~/lib/utils/axios_utils';
import { SAVE_INTEGRATION_EVENT } from '~/integrations/constants';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/vue_shared/plugins/global_toast');
jest.mock('lodash/delay', () => (callback) => callback());

const FIXTURE = 'services/edit_service.html';
const mockFormSelector = '.js-integration-settings-form';

describe('IntegrationSettingsForm', () => {
  let integrationSettingsForm;

  const mockStoreDispatch = () => jest.spyOn(integrationSettingsForm.vue.$store, 'dispatch');

  beforeEach(() => {
    loadFixtures(FIXTURE);

    integrationSettingsForm = new IntegrationSettingsForm(mockFormSelector);
    integrationSettingsForm.init();
  });

  afterEach(() => {
    eventHub.dispose(); // clear event hub handlers
  });

  describe('constructor', () => {
    it('should initialize form element refs on class object', () => {
      expect(integrationSettingsForm.$form).toBeDefined();
      expect(integrationSettingsForm.$form.nodeName).toBe('FORM');
      expect(integrationSettingsForm.formSelector).toBe(mockFormSelector);
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
      jest.spyOn(integrationSettingsForm.$form, 'submit');
    });

    afterEach(() => {
      mockAxios.restore();
    });

    describe('when event hub receives `SAVE_INTEGRATION_EVENT`', () => {
      describe('when form is valid', () => {
        it('should submit the form', async () => {
          eventHub.$emit(SAVE_INTEGRATION_EVENT, true);
          await waitForPromises();

          expect(integrationSettingsForm.$form.submit).toHaveBeenCalledTimes(1);
        });
      });

      describe('when form is invalid', () => {
        it('should dispatch `setIsSaving` with `false` and not submit form', async () => {
          const dispatchSpy = mockStoreDispatch();

          eventHub.$emit(SAVE_INTEGRATION_EVENT, false);

          await waitForPromises();

          expect(dispatchSpy).toHaveBeenCalledWith('setIsSaving', false);
          expect(integrationSettingsForm.$form.submit).not.toHaveBeenCalled();
        });
      });
    });
  });
});
