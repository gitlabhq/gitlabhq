import { mount } from '@vue/test-utils';
import InstallationTabs from '~/packages/details/components/installation_tabs.vue';
import Tracking from '~/tracking';
import { TrackingActions } from '~/packages/details/constants';

describe('InstallationTabs', () => {
  let wrapper;
  let eventSpy;

  const trackingLabel = 'foo';

  function createComponent() {
    wrapper = mount(InstallationTabs, {
      propsData: {
        trackingLabel,
      },
    });
  }

  const installationTab = () => wrapper.find('.js-installation-tab > a');
  const setupTab = () => wrapper.find('.js-setup-tab > a');

  beforeEach(() => {
    eventSpy = jest.spyOn(Tracking, 'event');
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('tab change tracking', () => {
    it('should track when the setup tab is clicked', () => {
      setupTab().trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(eventSpy).toHaveBeenCalledWith(undefined, TrackingActions.REGISTRY_SETUP, {
          label: trackingLabel,
        });
      });
    });

    it('should track when the installation tab is clicked', () => {
      setupTab().trigger('click');

      return wrapper.vm
        .$nextTick()
        .then(() => {
          installationTab().trigger('click');
        })
        .then(() => {
          expect(eventSpy).toHaveBeenCalledWith(undefined, TrackingActions.INSTALLATION, {
            label: trackingLabel,
          });
        });
    });
  });
});
