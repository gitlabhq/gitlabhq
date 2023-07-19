import { shallowMount, mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import MrWidgetFailedToMerge from '~/vue_merge_request_widget/components/states/mr_widget_failed_to_merge.vue';
import StateContainer from '~/vue_merge_request_widget/components/state_container.vue';
import eventHub from '~/vue_merge_request_widget/event_hub';

describe('MRWidgetFailedToMerge', () => {
  const dummyIntervalId = 1337;
  let wrapper;

  const createComponent = (props = {}, mountFn = shallowMount) => {
    wrapper = mountFn(MrWidgetFailedToMerge, {
      propsData: {
        mr: {
          mergeError: 'Merge error happened',
        },
        ...props,
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
    jest.spyOn(window, 'setInterval').mockReturnValue(dummyIntervalId);
    jest.spyOn(window, 'clearInterval').mockImplementation();
  });

  describe('interval', () => {
    it('sets interval to refresh', () => {
      createComponent();

      expect(window.setInterval).toHaveBeenCalledWith(wrapper.vm.updateTimer, 1000);
      expect(wrapper.vm.intervalId).toBe(dummyIntervalId);
    });

    it('clears interval when destroying', () => {
      createComponent();
      wrapper.destroy();

      expect(window.clearInterval).toHaveBeenCalledWith(dummyIntervalId);
    });
  });

  describe('mergeError', () => {
    it('removes forced line breaks', async () => {
      createComponent({ mr: { mergeError: 'contains<br />line breaks<br />' } });

      await nextTick();

      expect(wrapper.find('[data-testid="merge-error"]').text()).toBe('contains line breaks.');
    });

    it('does not append an extra period', async () => {
      createComponent({ mr: { mergeError: 'contains a period.' } });

      await nextTick();

      expect(wrapper.find('[data-testid="merge-error"]').text()).toBe('contains a period.');
    });

    it('does not insert an extra space between the final character and the period', async () => {
      createComponent({ mr: { mergeError: 'contains a <a href="http://example.com">link</a>.' } });

      await nextTick();

      expect(wrapper.find('[data-testid="merge-error"]').text()).toBe('contains a link.');
    });

    it('removes extra spaces', async () => {
      createComponent({ mr: { mergeError: 'contains a      lot of         spaces    .' } });

      await nextTick();

      expect(wrapper.find('[data-testid="merge-error"]').text()).toBe('contains a lot of spaces.');
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
      createComponent({});

      wrapper.vm.refresh();

      await nextTick();

      const stateContainerWrapper = wrapper.findComponent(StateContainer);

      expect(stateContainerWrapper.exists()).toBe(true);
      expect(stateContainerWrapper.props('status')).toBe('loading');
      expect(stateContainerWrapper.text().trim()).toBe('Refreshing now');
    });
  });

  describe('while it is not regresing', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders failed icon', () => {
      createComponent({}, mount);

      expect(wrapper.find('[data-testid="status-failed-icon"]').exists()).toBe(true);
    });

    it('renders given error', () => {
      expect(wrapper.find('.has-error-message').text().trim()).toBe('Merge error happened.');
    });

    it('renders refresh button', () => {
      expect(wrapper.findComponent(StateContainer).props('actions')).toMatchObject([
        { text: 'Refresh now', onClick: expect.any(Function) },
      ]);
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
