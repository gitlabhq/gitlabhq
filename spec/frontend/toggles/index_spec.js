import { createWrapper } from '@vue/test-utils';
import { GlToggle } from '@gitlab/ui';
import { initToggle } from '~/toggles';

// Selectors
const TOGGLE_WRAPPER_CLASS = '.gl-toggle-wrapper';
const TOGGLE_LABEL_CLASS = '.gl-toggle-label';
const CHECKED_CLASS = '.is-checked';
const DISABLED_CLASS = '.is-disabled';
const LOADING_CLASS = '.toggle-loading';
const HELP_TEXT_SELECTOR = '[data-testid="toggle-help"]';

// Toggle settings
const toggleClassName = 'js-custom-toggle-class';
const toggleLabel = 'Toggle label';

describe('toggles/index.js', () => {
  let instance;
  let toggleWrapper;

  const createRootEl = (dataAttrs) => {
    const dataset = {
      label: toggleLabel,
      ...dataAttrs,
    };
    const el = document.createElement('span');
    el.classList.add(toggleClassName);

    Object.entries(dataset).forEach(([key, value]) => {
      el.dataset[key] = value;
    });

    document.body.appendChild(el);

    return el;
  };

  const initToggleWithOptions = (options = {}) => {
    const el = createRootEl(options);
    instance = initToggle(el);
    toggleWrapper = document.querySelector(TOGGLE_WRAPPER_CLASS);
  };

  afterEach(() => {
    document.body.innerHTML = '';
    instance = null;
  });

  describe('initToggle', () => {
    describe('default state', () => {
      beforeEach(() => {
        initToggleWithOptions();
      });

      it('attaches a GlToggle to the element', () => {
        expect(toggleWrapper).not.toBe(null);
        expect(toggleWrapper.querySelector(TOGGLE_LABEL_CLASS).textContent).toBe(toggleLabel);
      });

      it('passes CSS classes down to GlToggle', () => {
        expect(toggleWrapper.className).toContain(toggleClassName);
      });

      it('is not checked', () => {
        expect(toggleWrapper.querySelector(CHECKED_CLASS)).toBe(null);
      });

      it('is enabled', () => {
        expect(toggleWrapper.querySelector(DISABLED_CLASS)).toBe(null);
      });

      it('is not loading', () => {
        expect(toggleWrapper.querySelector(LOADING_CLASS)).toBe(null);
      });

      it('emits "change" event when value changes', () => {
        const wrapper = createWrapper(instance);
        const event = 'change';
        const listener = jest.fn();

        instance.$on(event, listener);

        expect(listener).toHaveBeenCalledTimes(0);

        wrapper.findComponent(GlToggle).vm.$emit(event, true);

        expect(listener).toHaveBeenCalledTimes(1);
        expect(listener).toHaveBeenLastCalledWith(true);

        wrapper.findComponent(GlToggle).vm.$emit(event, false);

        expect(listener).toHaveBeenCalledTimes(2);
        expect(listener).toHaveBeenLastCalledWith(false);
      });
    });

    describe('with custom options', () => {
      const name = 'toggle-name';
      const help = 'Help text';
      const foo = 'bar';
      const id = 'an-id';

      beforeEach(() => {
        initToggleWithOptions({
          name,
          id,
          isChecked: true,
          disabled: true,
          isLoading: true,
          help,
          labelPosition: 'hidden',
          foo,
        });
        toggleWrapper = document.querySelector(TOGGLE_WRAPPER_CLASS);
      });

      it('sets the custom name', () => {
        const input = toggleWrapper.querySelector('input[type="hidden"]');

        expect(input.name).toBe(name);
      });

      it('is checked', () => {
        expect(toggleWrapper.querySelector(CHECKED_CLASS)).not.toBe(null);
      });

      it('is disabled', () => {
        expect(toggleWrapper.querySelector(DISABLED_CLASS)).not.toBe(null);
      });

      it('is loading', () => {
        expect(toggleWrapper.querySelector(LOADING_CLASS)).not.toBe(null);
      });

      it('sets the custom help text', () => {
        expect(toggleWrapper.querySelector(HELP_TEXT_SELECTOR).textContent).toBe(help);
      });

      it('hides the label', () => {
        expect(
          toggleWrapper.querySelector(TOGGLE_LABEL_CLASS).classList.contains('gl-sr-only'),
        ).toBe(true);
      });

      it('passes custom dataset to the wrapper', () => {
        expect(toggleWrapper.dataset.foo).toBe('bar');
      });

      it('passes an id to the wrapper', () => {
        expect(toggleWrapper.id).toBe(id);
      });
    });
  });
});
