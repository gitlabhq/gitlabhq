import { shallowMount } from '@vue/test-utils';
import { GlButton, GlLink, GlFormGroup, GlFormInput } from '@gitlab/ui';
import ExternalDashboard from '~/operation_settings/components/external_dashboard.vue';
import { TEST_HOST } from 'helpers/test_constants';

describe('operation settings external dashboard component', () => {
  let wrapper;
  const externalDashboardPath = `http://mock-external-domain.com/external/dashboard/path`;
  const externalDashboardHelpPagePath = `${TEST_HOST}/help/page/path`;

  beforeEach(() => {
    wrapper = shallowMount(ExternalDashboard, {
      propsData: {
        externalDashboardPath,
        externalDashboardHelpPagePath,
      },
    });
  });

  it('renders header text', () => {
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
    let form;

    beforeEach(() => {
      form = wrapper.find('form');
    });

    describe('external dashboard url', () => {
      describe('input label', () => {
        let formGroup;

        beforeEach(() => {
          formGroup = form.find(GlFormGroup);
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
          input = form.find(GlFormInput);
        });

        it('defaults to externalDashboardPath prop', () => {
          expect(input.attributes().value).toBe(externalDashboardPath);
        });

        it('uses a placeholder', () => {
          expect(input.attributes().placeholder).toBe('https://my-org.gitlab.io/my-dashboards');
        });
      });

      describe('submit button', () => {
        let submit;

        beforeEach(() => {
          submit = form.find(GlButton);
        });

        it('renders button label', () => {
          expect(submit.text()).toBe('Save Changes');
        });
      });
    });
  });
});
