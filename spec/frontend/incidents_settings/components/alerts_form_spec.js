import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import AlertsSettingsForm from '~/incidents_settings/components/alerts_form.vue';
import { ERROR_MSG } from '~/incidents_settings/constants';
import createFlash from '~/flash';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/flash');
jest.mock('~/lib/utils/url_utility');

describe('Alert integration settings form', () => {
  let wrapper;

  const findForm = () => wrapper.find({ ref: 'settingsForm' });

  beforeEach(() => {
    wrapper = shallowMount(AlertsSettingsForm, {
      provide: {
        operationsSettingsEndpoint: 'operations/endpoint',
        alertSettings: {
          issueTemplateKey: 'selecte_tmpl',
          createIssue: true,
          sendEmail: false,
          templates: [],
        },
      },
    });
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('default state', () => {
    it('should match the default snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('form', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    it('should refresh the page on successful submit', () => {
      mock.onPatch().reply(200);
      findForm().trigger('submit');
      return waitForPromises().then(() => {
        expect(refreshCurrentPage).toHaveBeenCalled();
      });
    });

    it('should display a flah message on unsuccessful submit', () => {
      mock.onPatch().reply(400);
      findForm().trigger('submit');
      return waitForPromises().then(() => {
        expect(createFlash).toHaveBeenCalledWith(expect.stringContaining(ERROR_MSG), 'alert');
      });
    });
  });
});
