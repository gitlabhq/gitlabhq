import { GlButton, GlLink, GlFormGroup, GlFormInput, GlFormSelect } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { TEST_HOST } from 'helpers/test_constants';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import { timezones } from '~/monitoring/format_date';
import DashboardTimezone from '~/operation_settings/components/form_group/dashboard_timezone.vue';
import ExternalDashboard from '~/operation_settings/components/form_group/external_dashboard.vue';
import MetricsSettings from '~/operation_settings/components/metrics_settings.vue';

import store from '~/operation_settings/store';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/alert');

describe('operation settings external dashboard component', () => {
  let wrapper;

  const operationsSettingsEndpoint = `${TEST_HOST}/mock/ops/settings/endpoint`;
  const helpPage = `${TEST_HOST}/help/metrics/page/path`;
  const externalDashboardUrl = `http://mock-external-domain.com/external/dashboard/url`;
  const dashboardTimezoneSetting = timezones.LOCAL;

  const mountComponent = (shallow = true) => {
    const config = [
      MetricsSettings,
      {
        store: store({
          operationsSettingsEndpoint,
          helpPage,
          externalDashboardUrl,
          dashboardTimezoneSetting,
        }),
        stubs: {
          ExternalDashboard,
          DashboardTimezone,
        },
      },
    ];
    wrapper = shallow ? shallowMount(...config) : mount(...config);
  };

  beforeEach(() => {
    jest.spyOn(axios, 'patch').mockImplementation();
  });

  afterEach(() => {
    axios.patch.mockReset();
    refreshCurrentPage.mockReset();
    createAlert.mockReset();
  });

  it('renders header text', () => {
    mountComponent();
    expect(wrapper.find('.js-section-header').text()).toBe('Metrics');
  });

  describe('expand/collapse button', () => {
    it('renders as an expand button by default', () => {
      mountComponent();
      const button = wrapper.findComponent(GlButton);

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
      expect(subHeader.text()).toContain('Manage metrics dashboard settings.');
    });

    it('renders help page link', () => {
      const link = subHeader.findComponent(GlLink);

      expect(link.text()).toBe('Learn more.');
      expect(link.attributes().href).toBe(helpPage);
    });
  });

  describe('form', () => {
    describe('dashboard timezone', () => {
      describe('field label', () => {
        let formGroup;

        beforeEach(() => {
          mountComponent(false);
          formGroup = wrapper.findComponent(DashboardTimezone).findComponent(GlFormGroup);
        });

        it('uses label text', () => {
          expect(formGroup.find('label').text()).toBe('Dashboard timezone');
        });

        it('uses description text', () => {
          const description = formGroup.find('small');
          const expectedDescription =
            "Choose whether to display dashboard metrics in UTC or the user's local timezone.";

          expect(description.text()).toBe(expectedDescription);
        });
      });

      describe('select field', () => {
        let select;

        beforeEach(() => {
          mountComponent();
          select = wrapper.findComponent(DashboardTimezone).findComponent(GlFormSelect);
        });

        it('defaults to externalDashboardUrl', () => {
          expect(select.attributes('value')).toBe(dashboardTimezoneSetting);
        });
      });
    });

    describe('external dashboard', () => {
      describe('input label', () => {
        let formGroup;

        beforeEach(() => {
          mountComponent(false);
          formGroup = wrapper.findComponent(ExternalDashboard).findComponent(GlFormGroup);
        });

        it('uses label text', () => {
          expect(formGroup.find('label').text()).toBe('External dashboard URL');
        });

        it('uses description text', () => {
          const description = formGroup.find('small');
          const expectedDescription =
            'Add a button to the metrics dashboard linking directly to your existing external dashboard.';

          expect(description.text()).toBe(expectedDescription);
        });
      });

      describe('input field', () => {
        let input;

        beforeEach(() => {
          mountComponent();
          input = wrapper.findComponent(ExternalDashboard).findComponent(GlFormInput);
        });

        it('defaults to externalDashboardUrl', () => {
          expect(input.attributes().value).toBe(externalDashboardUrl);
        });

        it('uses a placeholder', () => {
          expect(input.attributes().placeholder).toBe('https://my-org.gitlab.io/my-dashboards');
        });
      });
    });

    describe('submit button', () => {
      const findSubmitButton = () => wrapper.find('.settings-content form').findComponent(GlButton);

      const endpointRequest = [
        operationsSettingsEndpoint,
        {
          project: {
            metrics_setting_attributes: {
              dashboard_timezone: dashboardTimezoneSetting,
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

      it('submits form on click', async () => {
        mountComponent(false);
        axios.patch.mockResolvedValue();
        findSubmitButton().trigger('click');

        expect(axios.patch).toHaveBeenCalledWith(...endpointRequest);

        await nextTick();
        expect(refreshCurrentPage).toHaveBeenCalled();
      });

      it('creates an alert on error', async () => {
        mountComponent(false);
        const message = 'mockErrorMessage';
        axios.patch.mockRejectedValue({ response: { data: { message } } });
        findSubmitButton().trigger('click');

        expect(axios.patch).toHaveBeenCalledWith(...endpointRequest);

        await nextTick();
        await jest.runAllTicks();
        expect(createAlert).toHaveBeenCalledWith({
          message: `There was an error saving your changes. ${message}`,
        });
      });
    });
  });
});
