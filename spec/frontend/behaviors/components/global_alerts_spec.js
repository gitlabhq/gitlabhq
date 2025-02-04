import { nextTick } from 'vue';
import { GlAlert } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GlobalAlerts from '~/behaviors/components/global_alerts.vue';
import {
  GLOBAL_ALERTS_DISMISS_EVENT,
  eventHub,
  getGlobalAlerts,
  setGlobalAlerts,
  removeGlobalAlertById,
} from '~/lib/utils/global_alerts';

jest.mock('~/lib/utils/global_alerts', () => ({
  ...jest.requireActual('~/lib/utils/global_alerts'),
  getGlobalAlerts: jest.fn(),
  setGlobalAlerts: jest.fn(),
  removeGlobalAlertById: jest.fn(),
}));

describe('GlobalAlerts', () => {
  const alert1 = {
    dismissible: true,
    persistOnPages: [],
    id: 'foo',
    variant: 'success',
    title: 'Foo title',
    message: 'Foo',
  };
  const alert2 = {
    dismissible: true,
    persistOnPages: [],
    id: 'bar',
    variant: 'danger',
    message: 'Bar',
  };
  const alert3 = {
    dismissible: true,
    persistOnPages: ['dashboard:groups:index'],
    id: 'baz',
    variant: 'info',
    message: 'Baz',
  };

  let wrapper;

  const createComponent = async () => {
    wrapper = shallowMountExtended(GlobalAlerts);
    await nextTick();
  };

  const findAllAlerts = () => wrapper.findAllComponents(GlAlert);

  describe('created', () => {
    beforeEach(() => {
      getGlobalAlerts.mockImplementationOnce(() => []);

      jest.spyOn(eventHub, '$on').mockImplementation();
    });

    it(`should register the "${GLOBAL_ALERTS_DISMISS_EVENT}" event handler in the event hub`, async () => {
      await createComponent();

      expect(eventHub.$on).toHaveBeenCalledWith(GLOBAL_ALERTS_DISMISS_EVENT, expect.any(Function));
    });
  });

  describe('beforeDestroy', () => {
    beforeEach(() => {
      getGlobalAlerts.mockImplementationOnce(() => []);

      jest.spyOn(eventHub, '$off').mockImplementation();
    });

    it(`should remove the "${GLOBAL_ALERTS_DISMISS_EVENT}" event handler from the event hub`, async () => {
      await createComponent();

      wrapper.destroy();

      expect(eventHub.$off).toHaveBeenCalledWith(GLOBAL_ALERTS_DISMISS_EVENT, expect.any(Function));
    });
  });

  describe('when there are alerts to display', () => {
    beforeEach(() => {
      getGlobalAlerts.mockImplementationOnce(() => [alert1, alert2]);
    });

    it('displays alerts and removes them from session storage', async () => {
      await createComponent();

      const alerts = findAllAlerts();

      expect(alerts.at(0).text()).toBe('Foo');
      expect(alerts.at(0).props()).toMatchObject({
        title: 'Foo title',
        variant: 'success',
        dismissible: true,
      });

      expect(alerts.at(1).text()).toBe('Bar');
      expect(alerts.at(1).props()).toMatchObject({
        variant: 'danger',
        dismissible: true,
      });

      expect(setGlobalAlerts).toHaveBeenCalledWith([]);
    });

    describe('when alert is dismissed', () => {
      it('removes alert', async () => {
        await createComponent();

        wrapper.findComponent(GlAlert).vm.$emit('dismiss');
        await nextTick();

        expect(findAllAlerts().length).toBe(1);
        expect(removeGlobalAlertById).toHaveBeenCalledWith(alert1.id);
      });
    });

    describe(`when alert is dismissed by ID`, () => {
      it('removes alert', async () => {
        await createComponent();

        eventHub.$emit(GLOBAL_ALERTS_DISMISS_EVENT, alert1.id);

        await nextTick();

        expect(findAllAlerts()).toHaveLength(1);
        expect(removeGlobalAlertById).toHaveBeenCalledWith(alert1.id);
      });
    });
  });

  describe('when alert has `persistOnPages` key set', () => {
    const alerts = [alert3];

    beforeEach(() => {
      getGlobalAlerts.mockImplementationOnce(() => alerts);
    });

    describe('when page matches specified page', () => {
      beforeEach(() => {
        document.body.dataset.page = 'dashboard:groups:index';
      });

      afterEach(() => {
        delete document.body.dataset.page;
      });

      it('renders alert and does not remove it from session storage', async () => {
        await createComponent();

        expect(wrapper.findComponent(GlAlert).text()).toBe('Baz');
        expect(setGlobalAlerts).toHaveBeenCalledWith(alerts);
      });
    });

    describe('when page does not match specified page', () => {
      beforeEach(() => {
        document.body.dataset.page = 'dashboard:groups:show';
      });

      afterEach(() => {
        delete document.body.dataset.page;
      });

      it('does not render alert and does not remove it from session storage', async () => {
        await createComponent();

        expect(wrapper.findComponent(GlAlert).exists()).toBe(false);
        expect(setGlobalAlerts).toHaveBeenCalledWith(alerts);
      });
    });
  });

  describe('when there are no alerts to display', () => {
    beforeEach(() => {
      getGlobalAlerts.mockImplementationOnce(() => []);
    });

    it('renders nothing', async () => {
      await createComponent();

      expect(wrapper.find('*').exists()).toBe(false);
    });
  });
});
