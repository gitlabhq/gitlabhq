import { shallowMount } from '@vue/test-utils';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

const STORAGE_KEY = 'key';

describe('Local Storage Sync', () => {
  let wrapper;

  const createComponent = ({ value, asString = false, slots = {} } = {}) => {
    wrapper = shallowMount(LocalStorageSync, {
      propsData: { storageKey: STORAGE_KEY, value, asString },
      slots,
    });
  };

  const setStorageValue = (value) => localStorage.setItem(STORAGE_KEY, value);
  const getStorageValue = (value) => localStorage.getItem(STORAGE_KEY, value);

  afterEach(() => {
    localStorage.clear();
  });

  it('is a renderless component', () => {
    const html = '<div class="test-slot"></div>';
    createComponent({
      slots: {
        default: html,
      },
    });

    expect(wrapper.html()).toBe(html);
  });

  describe('localStorage empty', () => {
    it('does not emit input event', () => {
      createComponent({ value: 'ascending' });

      expect(wrapper.emitted('input')).toBeUndefined();
    });

    it('does not save initial value if it did not change', () => {
      createComponent({ value: 'ascending' });

      expect(getStorageValue()).toBeNull();
    });
  });

  describe('localStorage has saved value', () => {
    const savedValue = 'last_updated';

    beforeEach(() => {
      setStorageValue(savedValue);
      createComponent({ asString: true });
    });

    it('emits input event with saved value', () => {
      expect(wrapper.emitted('input')[0][0]).toBe(savedValue);
    });

    it('does not overwrite localStorage with initial prop value', () => {
      expect(getStorageValue()).toBe(savedValue);
    });

    it('updating the value updates localStorage', async () => {
      const newValue = 'last_updated';
      await wrapper.setProps({ value: newValue });

      expect(getStorageValue()).toBe(newValue);
    });
  });

  describe('persist prop', () => {
    it('persists the value by default', async () => {
      const persistedValue = 'persisted';
      createComponent({ asString: true });
      // Sanity check to make sure we start with nothing saved.
      expect(getStorageValue()).toBeNull();

      await wrapper.setProps({ value: persistedValue });

      expect(getStorageValue()).toBe(persistedValue);
    });

    it('does not save a value if persist is set to false', async () => {
      const value = 'saved';
      const notPersistedValue = 'notPersisted';
      createComponent({ asString: true });
      // Save some value so we can test that it's not overwritten.
      await wrapper.setProps({ value });

      expect(getStorageValue()).toBe(value);

      await wrapper.setProps({ persist: false, value: notPersistedValue });

      expect(getStorageValue()).toBe(value);
    });
  });

  describe('saving and restoring', () => {
    it.each`
      value             | asString
      ${'foo'}          | ${true}
      ${'foo'}          | ${false}
      ${'{ a: 1 }'}     | ${true}
      ${'{ a: 1 }'}     | ${false}
      ${3}              | ${false}
      ${['foo', 'bar']} | ${false}
      ${{ foo: 'bar' }} | ${false}
      ${null}           | ${false}
      ${' '}            | ${false}
      ${true}           | ${false}
      ${false}          | ${false}
      ${42}             | ${false}
      ${'42'}           | ${false}
      ${'{ foo: '}      | ${false}
    `('saves and restores the same value', async ({ value, asString }) => {
      // Create an initial component to save the value.
      createComponent({ asString });
      await wrapper.setProps({ value });
      wrapper.destroy();
      // Create a second component to restore the value. Restore is only done once, when the
      // component is first mounted.
      createComponent({ asString });

      expect(wrapper.emitted('input')[0][0]).toEqual(value);
    });

    it('shows a warning when trying to save a non-string value when asString prop is true', async () => {
      const spy = jest.spyOn(console, 'warn').mockImplementation();
      createComponent({ asString: true });
      await wrapper.setProps({ value: [] });

      expect(spy).toHaveBeenCalled();
    });
  });

  describe('with bad JSON in storage', () => {
    const badJSON = '{ badJSON';
    let spy;

    beforeEach(() => {
      spy = jest.spyOn(console, 'warn').mockImplementation();
      setStorageValue(badJSON);
      createComponent();
    });

    it('should console warn', () => {
      expect(spy).toHaveBeenCalled();
    });

    it('should not emit an input event', () => {
      expect(wrapper.emitted('input')).toBeUndefined();
    });
  });

  it('clears localStorage when clear property is true', async () => {
    const value = 'initial';
    createComponent({ asString: true });
    await wrapper.setProps({ value });

    expect(getStorageValue()).toBe(value);

    await wrapper.setProps({ clear: true });

    expect(getStorageValue()).toBeNull();
  });
});
