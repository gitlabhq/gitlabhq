import { mount, shallowMount } from '@vue/test-utils';
import { Document } from 'yaml';
import InputWrapper from '~/pipeline_wizard/components/input_wrapper.vue';
import TextWidget from '~/pipeline_wizard/components/widgets/text.vue';

describe('Pipeline Wizard -- Input Wrapper', () => {
  let wrapper;

  const createComponent = (props = {}, mountFunc = mount) => {
    wrapper = mountFunc(InputWrapper, {
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

  describe('API', () => {
    const inputValue = 'dslkfjsdlkfjlskdjfn';
    let inputChild;

    beforeEach(() => {
      createComponent({});
      inputChild = wrapper.findComponent(TextWidget);
    });

    it('will replace its value in compiled', async () => {
      await inputChild.vm.$emit('input', inputValue);
      const expected = new Document({
        bar: 'baz',
        foo: { some: inputValue },
      });
      expect(wrapper.emitted()['update:compiled']).toEqual([[expected]]);
    });

    it('will emit a highlight event with the correct path if child emits an input event', async () => {
      await inputChild.vm.$emit('input', inputValue);
      const expected = ['foo', 'some'];
      expect(wrapper.emitted().highlight).toEqual([[expected]]);
    });
  });

  describe('Target Path Discovery', () => {
    it.each`
      scenario                  | template                             | target     | expected
      ${'simple nested object'} | ${{ foo: { bar: { baz: '$BOO' } } }} | ${'$BOO'}  | ${['foo', 'bar', 'baz']}
      ${'list, first pos.'}     | ${{ foo: ['$BOO'] }}                 | ${'$BOO'}  | ${['foo', 0]}
      ${'list, second pos.'}    | ${{ foo: ['bar', '$BOO'] }}          | ${'$BOO'}  | ${['foo', 1]}
      ${'lowercase target'}     | ${{ foo: { bar: '$jupp' } }}         | ${'$jupp'} | ${['foo', 'bar']}
      ${'root list'}            | ${['$BOO']}                          | ${'$BOO'}  | ${[0]}
    `('$scenario', ({ template, target, expected }) => {
      createComponent(
        {
          template: new Document({ template }).get('template'),
          target,
        },
        shallowMount,
      );
      expect(wrapper.vm.path).toEqual(expected);
    });
  });
});
