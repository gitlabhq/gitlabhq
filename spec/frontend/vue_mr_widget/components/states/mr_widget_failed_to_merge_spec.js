import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import StatusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';
import MrWidgetFailedToMerge from '~/vue_merge_request_widget/components/states/mr_widget_failed_to_merge.vue';
import eventHub from '~/vue_merge_request_widget/event_hub';

describe('MRWidgetFailedToMerge', () => {
  const dummyIntervalId = 1337;
  let wrapper;

  const createComponent = (props = {}, data = {}) => {
    wrapper = shallowMount(MrWidgetFailedToMerge, {
      propsData: {
        mr: {
          mergeError: 'Merge error happened',
        },
        ...props,
      },
      data() {
        return data;
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
    jest.spyOn(window, 'setInterval').mockReturnValue(dummyIntervalId);
    jest.spyOn(window, 'clearInterval').mockImplementation();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('interval', () => {
    it('sets interval to refresh', () => {
      createComponent();

      expect(window.setInterval).toHaveBeenCalledWith(wrapper.vm.updateTimer, 1000);
      expect(wrapper.vm.intervalId).toBe(dummyIntervalId);
    });

    it('clears interval when destroying ', () => {
      createComponent();
      wrapper.destroy();

      expect(window.clearInterval).toHaveBeenCalledWith(dummyIntervalId);
    });
  });

  describe('mergeError', () => {
    it('removes forced line breaks', async () => {
      createComponent({ mr: { mergeError: 'contains<br />line breaks<br />' } });

      await nextTick();

      expect(wrapper.vm.mergeError).toBe('contains line breaks.');
    });
  });

  describe('created', () => {
    it('should disable polling', () => {
      createComponent();

      expect(eventHub.$emit).toHaveBeenCalledWith('DisablePolling');
    });
  });

  describe('methods', () => {
    describe('refresh', () => {
      it('should emit event to request component refresh', () => {
        createComponent();

        expect(wrapper.vm.isRefreshing).toBe(false);

        wrapper.vm.refresh();

        expect(wrapper.vm.isRefreshing).toBe(true);
        expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetUpdateRequested');
        expect(eventHub.$emit).toHaveBeenCalledWith('EnablePolling');
      });
    });

    describe('updateTimer', () => {
      it('should update timer and emit event when timer end', () => {
        createComponent();

        jest.spyOn(wrapper.vm, 'refresh').mockImplementation(() => {});

        expect(wrapper.vm.timer).toEqual(10);

        for (let i = 0; i < 10; i += 1) {
          expect(wrapper.vm.timer).toEqual(10 - i);
          wrapper.vm.updateTimer();
        }

        expect(wrapper.vm.refresh).toHaveBeenCalled();
      });
    });
  });

  describe('while it is refreshing', () => {
    it('renders Refresing now', async () => {
      createComponent({}, { isRefreshing: true });

      await nextTick();

      expect(wrapper.find('.js-refresh-label').text().trim()).toBe('Refreshing now');
    });
  });

  describe('while it is not regresing', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders warning icon and disabled merge button', () => {
      expect(wrapper.find('.js-ci-status-icon-warning')).not.toBeNull();
      expect(wrapper.find(StatusIcon).props('showDisabledButton')).toBe(true);
    });

    it('renders given error', () => {
      expect(wrapper.find('.has-error-message').text().trim()).toBe('Merge error happened.');
    });

    it('renders refresh button', () => {
      expect(
        wrapper.find('[data-testid="merge-request-failed-refresh-button"]').text().trim(),
      ).toBe('Refresh now');
    });

    it('renders remaining time', () => {
      expect(wrapper.find('.has-custom-error').text().trim()).toBe(
        'Refreshing in 10 seconds to show the updated status...',
      );
    });
  });

  it('should just generic merge failed message if merge_error is not available', async () => {
    createComponent({ mr: { mergeError: null } });

    await nextTick();

    expect(wrapper.text().trim()).toContain('Merge failed.');
    expect(wrapper.text().trim()).not.toContain('Merge error happened.');
  });

  it('should show refresh label when refresh requested', async () => {
    createComponent();

    wrapper.vm.refresh();

    await nextTick();

    expect(wrapper.text().trim()).not.toContain('Merge failed. Refreshing');
    expect(wrapper.text().trim()).toContain('Refreshing now');
  });
});
