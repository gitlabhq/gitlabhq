import { GlFormGroup, GlFormInput, GlFormInputGroup, GlLink } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';

import ColorPicker from '~/vue_shared/components/color_picker/color_picker.vue';

jest.mock('lodash/uniqueId', () => (prefix) => (prefix ? `${prefix}1` : 1));

describe('ColorPicker', () => {
  let wrapper;

  const createComponent = (fn = mount, propsData = {}) => {
    wrapper = fn(ColorPicker, {
      propsData,
    });
  };

  const setColor = '#000000';
  const invalidText = 'Please enter a valid hex (#RRGGBB or #RGB) color value';
  const findGlFormGroup = () => wrapper.findComponent(GlFormGroup);
  const colorPreview = () => wrapper.find('[data-testid="color-preview"]');
  const colorPicker = () => wrapper.findComponent(GlFormInput);
  const colorInput = () => wrapper.find('input[type="color"]');
  const colorTextInput = () => wrapper.findComponent(GlFormInputGroup).find('input[type="text"]');
  const invalidFeedback = () => wrapper.find('.invalid-feedback');
  const description = () => wrapper.findComponent(GlFormGroup).attributes('description');
  const presetColors = () => wrapper.findAllComponents(GlLink);

  beforeEach(() => {
    gon.suggested_label_colors = {
      [setColor]: 'Black',
      '#0033CC': 'UA blue',
      '#428BCA': 'Moderate blue',
      '#44AD8E': 'Lime green',
    };
  });

  describe('label', () => {
    it('hides the label if the label is not passed', () => {
      createComponent(shallowMount);

      expect(findGlFormGroup().attributes('label')).toBe('');
    });

    it('shows the label if the label is passed', () => {
      createComponent(shallowMount, { label: 'test' });

      expect(findGlFormGroup().attributes('label')).toBe('test');
    });

    describe.each`
      desc                 | id
      ${'with prop id'}    | ${'test-id'}
      ${'without prop id'} | ${undefined}
    `('$desc', ({ id }) => {
      beforeEach(() => {
        createComponent(mount, { id, label: 'test' });
      });

      it('renders the same `ID` for input and `for` for label', () => {
        expect(findGlFormGroup().find('label').attributes('for')).toBe(
          colorInput().attributes('id'),
        );
      });
    });
  });

  describe('behavior', () => {
    it('by default has no values', () => {
      createComponent();

      expect(colorPreview().attributes('style')).toBe(undefined);
      expect(colorPicker().attributes('value')).toBe(undefined);
      expect(colorTextInput().props('value')).toBe('');
      expect(colorPreview().attributes('class')).toContain('gl-shadow-inner-1-gray-400');
    });

    it('has a color set on initialization', () => {
      createComponent(mount, { value: setColor });

      expect(colorTextInput().props('value')).toBe(setColor);
    });

    it('emits input event from component when a color is selected', async () => {
      createComponent();
      await colorTextInput().setValue(setColor);

      expect(wrapper.emitted().input[0]).toStrictEqual([setColor]);
    });

    it('trims spaces from submitted colors', async () => {
      createComponent();
      await colorTextInput().setValue(`    ${setColor}    `);

      expect(wrapper.emitted().input[0]).toStrictEqual([setColor]);
      expect(colorPreview().attributes('class')).toContain('gl-shadow-inner-1-gray-400');
      expect(colorTextInput().attributes('class')).not.toContain('is-invalid');
    });

    it('shows invalid feedback when the state is marked as invalid', () => {
      createComponent(mount, { invalidFeedback: invalidText, state: false });

      expect(invalidFeedback().text()).toBe(invalidText);
      expect(colorPreview().attributes('class')).toContain('gl-shadow-inner-1-red-500');
      expect(colorTextInput().attributes('class')).toContain('is-invalid');
    });
  });

  describe('inputs', () => {
    it('has color input value entered', async () => {
      createComponent();
      await colorTextInput().setValue(setColor);

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

      expect(description()).toBe('Enter any color.');
      expect(presetColors().exists()).toBe(false);
    });

    it('shows the suggested colors', () => {
      createComponent(shallowMount);
      expect(description()).toBe('Enter any color or choose one of the suggested colors below.');
      expect(presetColors()).toHaveLength(4);
    });

    it('has preset color selected', async () => {
      createComponent();
      await presetColors().at(0).trigger('click');

      expect(wrapper.emitted().input[0]).toStrictEqual([setColor]);
    });

    it('shows the suggested colors passed using props', () => {
      const customColors = {
        '#ff0000': 'Red',
        '#808080': 'Gray',
      };

      createComponent(shallowMount, { suggestedColors: customColors });
      expect(description()).toBe('Enter any color or choose one of the suggested colors below.');
      expect(presetColors()).toHaveLength(2);
      expect(presetColors().at(0).attributes('title')).toBe('Red');
      expect(presetColors().at(1).attributes('title')).toBe('Gray');
    });
  });
});
