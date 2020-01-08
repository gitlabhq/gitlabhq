import { mount, shallowMount } from '@vue/test-utils';
import { GlButton, GlLink, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';
import ExternalDashboard from '~/operation_settings/components/external_dashboard.vue';
import store from '~/operation_settings/store';
import axios from '~/lib/utils/axios_utils';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import createFlash from '~/flash';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/flash');

describe('operation settings external dashboard component', () => {
  let wrapper;
  const operationsSettingsEndpoint = `${TEST_HOST}/mock/ops/settings/endpoint`;
  const externalDashboardUrl = `http://mock-external-domain.com/external/dashboard/url`;
  const externalDashboardHelpPagePath = `${TEST_HOST}/help/page/path`;
  const mountComponent = (shallow = true) => {
    const config = [
      ExternalDashboard,
      {
        store: store({
          operationsSettingsEndpoint,
          externalDashboardUrl,
          externalDashboardHelpPagePath,
        }),
      },
    ];
    wrapper = shallow ? shallowMount(...config) : mount(...config);
  };

  beforeEach(() => {
    jest.spyOn(axios, 'patch').mockImplementation();
  });

  afterEach(() => {
    if (wrapper.destroy) {
      wrapper.destroy();
    }
    axios.patch.mockReset();
    refreshCurrentPage.mockReset();
    createFlash.mockReset();
  });

  it('renders header text', () => {
    mountComponent();
    expect(wrapper.find('.js-section-header').text()).toBe('External Dashboard');
  });

  describe('expand/collapse button', () => {
    it('renders as an expand button by default', () => {
      const button = wrapper.find(GlButton);

      expect(button.text()).toBe('Expand');
    });
  });

  describe('sub-header', () => {
    let subHeader;

    beforeEach(() => {
      mountComponent();
      subHeader = wrapper.find('.js-section-sub-header');
    });

    it('renders descriptive text', () => {
      expect(subHeader.text()).toContain(
        'Add a button to the metrics dashboard linking directly to your existing external dashboards.',
      );
    });

    it('renders help page link', () => {
      const link = subHeader.find(GlLink);

      expect(link.text()).toBe('Learn more');
      expect(link.attributes().href).toBe(externalDashboardHelpPagePath);
    });
  });

  describe('form', () => {
    describe('input label', () => {
      let formGroup;

      beforeEach(() => {
        mountComponent();
        formGroup = wrapper.find(GlFormGroup);
      });

      it('uses label text', () => {
        expect(formGroup.attributes().label).toBe('Full dashboard URL');
      });

      it('uses description text', () => {
        expect(formGroup.attributes().description).toBe(
          'Enter the URL of the dashboard you want to link to',
        );
      });
    });

    describe('input field', () => {
      let input;

      beforeEach(() => {
        mountComponent();
        input = wrapper.find(GlFormInput);
      });

      it('defaults to externalDashboardUrl', () => {
        expect(input.attributes().value).toBe(externalDashboardUrl);
      });

      it('uses a placeholder', () => {
        expect(input.attributes().placeholder).toBe('https://my-org.gitlab.io/my-dashboards');
      });
    });

    describe('submit button', () => {
      const findSubmitButton = () => wrapper.find('.settings-content form').find(GlButton);

      const endpointRequest = [
        operationsSettingsEndpoint,
        {
          project: {
            metrics_setting_attributes: {
              external_dashboard_url: externalDashboardUrl,
            },
          },
        },
      ];

      it('renders button label', () => {
        mountComponent();
        const submit = findSubmitButton();
        expect(submit.text()).toBe('Save Changes');
      });

      it('submits form on click', () => {
        mountComponent(false);
        axios.patch.mockResolvedValue();
        findSubmitButton().trigger('click');

        expect(axios.patch).toHaveBeenCalledWith(...endpointRequest);

        return wrapper.vm.$nextTick().then(() => expect(refreshCurrentPage).toHaveBeenCalled());
      });

      it('creates flash banner on error', () => {
        mountComponent(false);
        const message = 'mockErrorMessage';
        axios.patch.mockRejectedValue({ response: { data: { message } } });
        findSubmitButton().trigger('click');

        expect(axios.patch).toHaveBeenCalledWith(...endpointRequest);

        return wrapper.vm
          .$nextTick()
          .then(jest.runAllTicks)
          .then(() =>
            expect(createFlash).toHaveBeenCalledWith(
              `There was an error saving your changes. ${message}`,
              'alert',
            ),
          );
      });
    });
  });
});
