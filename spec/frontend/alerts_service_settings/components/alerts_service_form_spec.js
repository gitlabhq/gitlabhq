import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import AlertsServiceForm from '~/alerts_service_settings/components/alerts_service_form.vue';
import ToggleButton from '~/vue_shared/components/toggle_button.vue';
import createFlash from '~/flash';

jest.mock('~/flash');

const defaultProps = {
  initialAuthorizationKey: 'abcedfg123',
  formPath: 'http://invalid',
  url: 'https://gitlab.com/endpoint-url',
  alertsSetupUrl: 'http://invalid',
  alertsUsageUrl: 'http://invalid',
  initialActivated: false,
};

describe('AlertsServiceForm', () => {
  let wrapper;
  let mockAxios;

  const createComponent = (props = defaultProps, { methods } = {}) => {
    wrapper = shallowMount(AlertsServiceForm, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      methods,
    });
  };

  const findUrl = () => wrapper.find('#url');
  const findAuthorizationKey = () => wrapper.find('#authorization-key');
  const findDescription = () => wrapper.find('[data-testid="description"');
  const findActiveStatusIcon = val =>
    document.querySelector(`.js-service-active-status[data-value=${val.toString()}]`);

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    setFixtures(`
    <div>
      <span class="js-service-active-status fa fa-circle" data-value="true"></span>
      <span class="js-service-active-status fa fa-power-off" data-value="false"></span>
    </div>`);
  });

  afterEach(() => {
    wrapper.destroy();
    mockAxios.restore();
  });

  describe('with default values', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders "url" input', () => {
      expect(findUrl().html()).toMatchSnapshot();
    });

    it('renders "authorization-key" input', () => {
      expect(findAuthorizationKey().html()).toMatchSnapshot();
    });

    it('renders toggle button', () => {
      expect(wrapper.find(ToggleButton).html()).toMatchSnapshot();
    });

    it('shows description and docs links', () => {
      expect(findDescription().element.innerHTML).toMatchSnapshot();
    });
  });

  describe('reset key', () => {
    it('triggers resetKey method', () => {
      const resetKey = jest.fn();
      const methods = { resetKey };
      createComponent(defaultProps, { methods });

      wrapper.find(GlModal).vm.$emit('ok');

      expect(resetKey).toHaveBeenCalled();
    });

    it('updates the authorization key on success', () => {
      const formPath = 'some/path';
      mockAxios.onPut(formPath, { service: { token: '' } }).replyOnce(200, { token: 'newToken' });

      createComponent({ formPath });

      return wrapper.vm.resetKey().then(() => {
        expect(findAuthorizationKey().attributes('value')).toBe('newToken');
      });
    });

    it('shows flash message on error', () => {
      const formPath = 'some/path';
      mockAxios.onPut(formPath).replyOnce(404);

      createComponent({ formPath });

      return wrapper.vm.resetKey().then(() => {
        expect(findAuthorizationKey().attributes('value')).toBe(
          defaultProps.initialAuthorizationKey,
        );
        expect(createFlash).toHaveBeenCalled();
      });
    });
  });

  describe('activate toggle', () => {
    it('triggers toggleActivated method', () => {
      const toggleActivated = jest.fn();
      const methods = { toggleActivated };
      createComponent(defaultProps, { methods });

      wrapper.find(ToggleButton).vm.$emit('change', true);

      expect(toggleActivated).toHaveBeenCalled();
    });

    describe('successfully completes', () => {
      describe.each`
        initialActivated | value
        ${false}         | ${true}
        ${true}          | ${false}
      `(
        'when initialActivated=$initialActivated and value=$value',
        ({ initialActivated, value }) => {
          beforeEach(() => {
            const formPath = 'some/path';
            mockAxios
              .onPut(formPath, { service: { active: value } })
              .replyOnce(200, { active: value });
            createComponent({ initialActivated, formPath });

            return wrapper.vm.toggleActivated(value);
          });

          it(`updates toggle button value to ${value}`, () => {
            expect(wrapper.find(ToggleButton).props('value')).toBe(value);
          });

          it('updates visible status icons', () => {
            expect(findActiveStatusIcon(!value)).toHaveClass('d-none');
            expect(findActiveStatusIcon(value)).not.toHaveClass('d-none');
          });
        },
      );
    });

    describe('error is encountered', () => {
      beforeEach(() => {
        const formPath = 'some/path';
        mockAxios.onPut(formPath).replyOnce(500);
      });

      it('restores previous value', () => {
        createComponent({ initialActivated: false });

        return wrapper.vm.toggleActivated(true).then(() => {
          expect(wrapper.find(ToggleButton).props('value')).toBe(false);
        });
      });
    });
  });
});
