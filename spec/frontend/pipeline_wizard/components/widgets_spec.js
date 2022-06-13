import fs from 'fs';
import { mount } from '@vue/test-utils';
import { Document } from 'yaml';
import InputWrapper from '~/pipeline_wizard/components/input_wrapper.vue';

describe('Test all widgets in ./widgets/* whether they provide a minimal api', () => {
  const createComponent = (props = {}, mountFunc = mount) => {
    mountFunc(InputWrapper, {
      propsData: {
        template: new Document({
          template: {
            bar: 'baz',
            foo: { some: '$TARGET' },
          },
        }).get('template'),
        compiled: new Document({ bar: 'baz', foo: { some: '$TARGET' } }),
        target: '$TARGET',
        widget: 'text',
        label: 'some label (required by the text widget)',
        ...props,
      },
    });
  };

  const widgets = fs
    .readdirSync('./app/assets/javascripts/pipeline_wizard/components/widgets')
    .map((filename) => [filename.match(/^(.*).vue$/)[1]]);
  let consoleErrorSpy;

  beforeAll(() => {
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterAll(() => {
    consoleErrorSpy.mockRestore();
  });

  describe.each(widgets)('`%s` Widget', (name) => {
    it('passes the input validator', () => {
      const validatorFunc = InputWrapper.props.widget.validator;
      expect(validatorFunc(name)).toBe(true);
    });

    it('mounts without error', () => {
      createComponent({ widget: name });
      expect(consoleErrorSpy).not.toHaveBeenCalled();
    });
  });
});
