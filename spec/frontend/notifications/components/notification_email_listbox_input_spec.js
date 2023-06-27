import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import ListboxInput from '~/vue_shared/components/listbox_input/listbox_input.vue';
import NotificationEmailListboxInput from '~/notifications/components/notification_email_listbox_input.vue';

describe('NotificationEmailListboxInput', () => {
  let wrapper;

  // Props
  const label = 'label';
  const name = 'name';
  const emails = ['test@gitlab.com'];
  const emptyValueText = 'emptyValueText';
  const value = 'value';
  const disabled = false;
  const placement = 'right';

  // Finders
  const findListboxInput = () => wrapper.findComponent(ListboxInput);

  const createComponent = (attachTo) => {
    wrapper = shallowMount(NotificationEmailListboxInput, {
      provide: {
        label,
        name,
        emails,
        emptyValueText,
        value,
        disabled,
        placement,
      },
      attachTo,
    });
  };

  describe('props', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      propName      | propValue
      ${'label'}    | ${label}
      ${'name'}     | ${name}
      ${'selected'} | ${value}
      ${'disabled'} | ${disabled}
    `('passes the $propName prop to ListboxInput', ({ propName, propValue }) => {
      expect(findListboxInput().props(propName)).toBe(propValue);
    });

    it('passes the options to ListboxInput', () => {
      expect(findListboxInput().props('items')).toStrictEqual([
        { text: emptyValueText, value: '' },
        { text: emails[0], value: emails[0] },
      ]);
    });
  });

  describe('form', () => {
    let form;

    beforeEach(() => {
      form = document.createElement('form');
      const root = document.createElement('div');
      form.appendChild(root);
      createComponent(root);
    });

    afterEach(() => {
      form = null;
    });

    it('submits the parent form when the value changes', async () => {
      jest.spyOn(form, 'submit');
      expect(form.submit).not.toHaveBeenCalled();

      findListboxInput().vm.$emit('select');
      await nextTick();

      expect(form.submit).toHaveBeenCalled();
    });
  });
});
