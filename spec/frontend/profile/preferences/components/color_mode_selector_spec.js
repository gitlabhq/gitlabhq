import { nextTick } from 'vue';
import { GlSegmentedControl } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ColorModeSelector from '~/profile/preferences/components/color_mode_selector.vue';

describe('ColorModeSelector component', () => {
  let wrapper;
  let formEl;
  let submitSpy;
  let submitListener;

  const colorModes = [
    { id: 1, name: 'Light', css_class: 'gl-light' },
    { id: 2, name: 'Dark', css_class: 'gl-dark' },
    { id: 3, name: 'Auto', css_class: 'gl-system' },
  ];

  const findSegmentedControl = () => wrapper.findComponent(GlSegmentedControl);
  const findHiddenInput = () => wrapper.find('input[type="hidden"]');

  function createComponent({ initialColorModeId = 1, remote = true } = {}) {
    // The component submits the closest <form>, so render it inside one.
    formEl = document.createElement('form');
    if (remote) {
      formEl.dataset.remote = 'true';
    }
    const mountEl = document.createElement('div');
    formEl.appendChild(mountEl);
    document.body.appendChild(formEl);

    submitSpy = jest.fn();
    // Listen on `document`, mirroring how rails-ujs binds its delegated submit
    // handler. This ensures the dispatched submit event bubbles (bubbles: true),
    // which is required for the remote form to actually be submitted.
    submitListener = (event) => {
      // Prevent jsdom "Not implemented: HTMLFormElement.prototype.requestSubmit" noise.
      event.preventDefault();
      submitSpy(event);
    };
    document.addEventListener('submit', submitListener);

    wrapper = mountExtended(ColorModeSelector, {
      attachTo: mountEl,
      propsData: {
        colorModes,
        initialColorModeId,
      },
    });
  }

  beforeEach(() => {
    jest.clearAllMocks();
  });

  afterEach(() => {
    if (submitListener) {
      document.removeEventListener('submit', submitListener);
    }
    formEl?.remove();
  });

  describe('rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a segmented control with an option per color mode', () => {
      expect(findSegmentedControl().props('options')).toEqual([
        { value: 1, text: 'Light' },
        { value: 2, text: 'Dark' },
        { value: 3, text: 'Auto' },
      ]);
    });

    it('selects the initial color mode', () => {
      expect(findSegmentedControl().props('value')).toBe(1);
      expect(findHiddenInput().element.value).toBe('1');
    });
  });

  describe('when a different color mode is selected', () => {
    beforeEach(async () => {
      createComponent({ initialColorModeId: 1 });
      findSegmentedControl().vm.$emit('input', 2);
      await nextTick();
      // Allow onChange's $nextTick(submitForm) to run.
      await nextTick();
    });

    it('updates the hidden input value', () => {
      expect(findHiddenInput().element.value).toBe('2');
    });

    it('submits the remote form via a native submit event', () => {
      expect(submitSpy).toHaveBeenCalledTimes(1);
    });

    it('reverts the selection without resubmitting when the save fails', async () => {
      formEl.dispatchEvent(new CustomEvent('ajax:error'));
      await nextTick();

      expect(findSegmentedControl().props('value')).toBe(1);
      expect(findHiddenInput().element.value).toBe('1');
      // The revert must not trigger another submit.
      expect(submitSpy).toHaveBeenCalledTimes(1);
    });
  });

  describe('when the form is not remote', () => {
    beforeEach(async () => {
      createComponent({ initialColorModeId: 1, remote: false });
      jest.spyOn(formEl, 'submit').mockImplementation();
      findSegmentedControl().vm.$emit('input', 3);
      await nextTick();
      await nextTick();
    });

    it('submits the form natively', () => {
      expect(formEl.submit).toHaveBeenCalled();
      // A native form.submit() bypasses submit event listeners.
      expect(submitSpy).not.toHaveBeenCalled();
    });
  });
});
