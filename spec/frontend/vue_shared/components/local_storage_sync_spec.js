import { shallowMount } from '@vue/test-utils';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

describe('Local Storage Sync', () => {
  let wrapper;

  const createComponent = ({ props = {}, slots = {} } = {}) => {
    wrapper = shallowMount(LocalStorageSync, {
      propsData: props,
      slots,
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
    wrapper = null;
    localStorage.clear();
  });

  it('is a renderless component', () => {
    const html = '<div class="test-slot"></div>';
    createComponent({
      props: {
        storageKey: 'key',
      },
      slots: {
        default: html,
      },
    });

    expect(wrapper.html()).toBe(html);
  });

  describe('localStorage empty', () => {
    const storageKey = 'issue_list_order';

    it('does not emit input event', () => {
      createComponent({
        props: {
          storageKey,
          value: 'ascending',
        },
      });

      expect(wrapper.emitted('input')).toBeFalsy();
    });

    it.each('foo', 3, true, ['foo', 'bar'], { foo: 'bar' })(
      'saves updated value to localStorage',
      newValue => {
        createComponent({
          props: {
            storageKey,
            value: 'initial',
          },
        });

        wrapper.setProps({ value: newValue });

        return wrapper.vm.$nextTick().then(() => {
          expect(localStorage.getItem(storageKey)).toBe(String(newValue));
        });
      },
    );

    it('does not save default value', () => {
      const value = 'ascending';

      createComponent({
        props: {
          storageKey,
          value,
        },
      });

      expect(localStorage.getItem(storageKey)).toBe(null);
    });
  });

  describe('localStorage has saved value', () => {
    const storageKey = 'issue_list_order_by';
    const savedValue = 'last_updated';

    beforeEach(() => {
      localStorage.setItem(storageKey, savedValue);
    });

    it('emits input event with saved value', () => {
      createComponent({
        props: {
          storageKey,
          value: 'ascending',
        },
      });

      expect(wrapper.emitted('input')[0][0]).toBe(savedValue);
    });

    it('does not overwrite localStorage with prop value', () => {
      createComponent({
        props: {
          storageKey,
          value: 'created',
        },
      });

      expect(localStorage.getItem(storageKey)).toBe(savedValue);
    });

    it('updating the value updates localStorage', () => {
      createComponent({
        props: {
          storageKey,
          value: 'created',
        },
      });

      const newValue = 'last_updated';
      wrapper.setProps({
        value: newValue,
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(localStorage.getItem(storageKey)).toBe(newValue);
      });
    });

    it('persists the value by default', async () => {
      const persistedValue = 'persisted';

      createComponent({
        props: {
          storageKey,
        },
      });

      wrapper.setProps({ value: persistedValue });
      await wrapper.vm.$nextTick();
      expect(localStorage.getItem(storageKey)).toBe(persistedValue);
    });

    it('does not save a value if persist is set to false', async () => {
      const notPersistedValue = 'notPersisted';

      createComponent({
        props: {
          storageKey,
        },
      });

      wrapper.setProps({ persist: false, value: notPersistedValue });
      await wrapper.vm.$nextTick();
      expect(localStorage.getItem(storageKey)).not.toBe(notPersistedValue);
    });
  });

  describe('with "asJson" prop set to "true"', () => {
    const storageKey = 'testStorageKey';

    describe.each`
      value             | serializedValue
      ${null}           | ${'null'}
      ${''}             | ${'""'}
      ${true}           | ${'true'}
      ${false}          | ${'false'}
      ${42}             | ${'42'}
      ${'42'}           | ${'"42"'}
      ${'{ foo: '}      | ${'"{ foo: "'}
      ${['test']}       | ${'["test"]'}
      ${{ foo: 'bar' }} | ${'{"foo":"bar"}'}
    `('given $value', ({ value, serializedValue }) => {
      describe('is a new value', () => {
        beforeEach(() => {
          createComponent({
            props: {
              storageKey,
              value: 'initial',
              asJson: true,
            },
          });

          wrapper.setProps({ value });

          return wrapper.vm.$nextTick();
        });

        it('serializes the value correctly to localStorage', () => {
          expect(localStorage.getItem(storageKey)).toBe(serializedValue);
        });
      });

      describe('is already stored', () => {
        beforeEach(() => {
          localStorage.setItem(storageKey, serializedValue);

          createComponent({
            props: {
              storageKey,
              value: 'initial',
              asJson: true,
            },
          });
        });

        it('emits an input event with the deserialized value', () => {
          expect(wrapper.emitted('input')).toEqual([[value]]);
        });
      });
    });

    describe('with bad JSON in storage', () => {
      const badJSON = '{ badJSON';

      beforeEach(() => {
        jest.spyOn(console, 'warn').mockImplementation();
        localStorage.setItem(storageKey, badJSON);

        createComponent({
          props: {
            storageKey,
            value: 'initial',
            asJson: true,
          },
        });
      });

      it('should console warn', () => {
        // eslint-disable-next-line no-console
        expect(console.warn).toHaveBeenCalledWith(
          `[gitlab] Failed to deserialize value from localStorage (key=${storageKey})`,
          badJSON,
        );
      });

      it('should not emit an input event', () => {
        expect(wrapper.emitted('input')).toBeUndefined();
      });
    });
  });

  it('clears localStorage when clear property is true', async () => {
    const storageKey = 'key';
    const value = 'initial';

    createComponent({
      props: {
        storageKey,
      },
    });
    wrapper.setProps({
      value,
    });

    await wrapper.vm.$nextTick();

    expect(localStorage.getItem(storageKey)).toBe(value);

    wrapper.setProps({
      clear: true,
    });

    await wrapper.vm.$nextTick();

    expect(localStorage.getItem(storageKey)).toBe(null);
  });
});
