import { GlFormGroup, GlFormInput, GlFormInputGroup, GlLink } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';

import ColorPicker from '~/vue_shared/components/color_picker/color_picker.vue';

describe('ColorPicker', () => {
  let wrapper;

  const createComponent = (fn = mount, propsData = {}) => {
    wrapper = fn(ColorPicker, {
      propsData,
    });
  };

  const setColor = '#000000';
  const invalidText = 'Please enter a valid hex (#RRGGBB or #RGB) color value';
  const label = () => wrapper.find(GlFormGroup).attributes('label');
  const colorPreview = () => wrapper.find('[data-testid="color-preview"]');
  const colorPicker = () => wrapper.find(GlFormInput);
  const colorInput = () => wrapper.find(GlFormInputGroup).find('input[type="text"]');
  const invalidFeedback = () => wrapper.find('.invalid-feedback');
  const description = () => wrapper.find(GlFormGroup).attributes('description');
  const presetColors = () => wrapper.findAll(GlLink);

  beforeEach(() => {
    gon.suggested_label_colors = {
      [setColor]: 'Black',
      '#0033CC': 'UA blue',
      '#428BCA': 'Moderate blue',
      '#44AD8E': 'Lime green',
    };
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('label', () => {
    it('hides the label if the label is not passed', () => {
      createComponent(shallowMount);

      expect(label()).toBe('');
    });

    it('shows the label if the label is passed', () => {
      createComponent(shallowMount, { label: 'test' });

      expect(label()).toBe('test');
    });
  });

  describe('behavior', () => {
    it('by default has no values', () => {
      createComponent();

      expect(colorPreview().attributes('style')).toBe(undefined);
      expect(colorPicker().attributes('value')).toBe(undefined);
      expect(colorInput().props('value')).toBe('');
      expect(colorPreview().attributes('class')).toContain('gl-inset-border-1-gray-400');
    });

    it('has a color set on initialization', () => {
      createComponent(mount, { value: setColor });

      expect(colorInput().props('value')).toBe(setColor);
    });

    it('emits input event from component when a color is selected', async () => {
      createComponent();
      await colorInput().setValue(setColor);

      expect(wrapper.emitted().input[0]).toStrictEqual([setColor]);
    });

    it('trims spaces from submitted colors', async () => {
      createComponent();
      await colorInput().setValue(`    ${setColor}    `);

      expect(wrapper.emitted().input[0]).toStrictEqual([setColor]);
      expect(colorPreview().attributes('class')).toContain('gl-inset-border-1-gray-400');
      expect(colorInput().attributes('class')).not.toContain('is-invalid');
    });

    it('shows invalid feedback when the state is marked as invalid', async () => {
      createComponent(mount, { invalidFeedback: invalidText, state: false });

      expect(invalidFeedback().text()).toBe(invalidText);
      expect(colorPreview().attributes('class')).toContain('gl-inset-border-1-red-500');
      expect(colorInput().attributes('class')).toContain('is-invalid');
    });
  });

  describe('inputs', () => {
    it('has color input value entered', async () => {
      createComponent();
      await colorInput().setValue(setColor);

      expect(wrapper.emitted().input[0]).toStrictEqual([setColor]);
    });

    it('has color picker value entered', async () => {
      createComponent();
      await colorPicker().setValue(setColor);

      expect(wrapper.emitted().input[0]).toStrictEqual([setColor]);
    });
  });

  describe('preset colors', () => {
    it('hides the suggested colors if they are empty', () => {
      gon.suggested_label_colors = {};
      createComponent(shallowMount);

      expect(description()).toBe('Choose any color');
      expect(presetColors().exists()).toBe(false);
    });

    it('shows the suggested colors', () => {
      createComponent(shallowMount);
      expect(description()).toBe(
        'Choose any color. Or you can choose one of the suggested colors below',
      );
      expect(presetColors()).toHaveLength(4);
    });

    it('has preset color selected', async () => {
      createComponent();
      await presetColors().at(0).trigger('click');

      expect(wrapper.emitted().input[0]).toStrictEqual([setColor]);
    });
  });
});
