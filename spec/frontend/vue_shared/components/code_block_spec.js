import { shallowMount } from '@vue/test-utils';
import CodeBlock from '~/vue_shared/components/code_block.vue';

describe('Code Block', () => {
  let wrapper;

  const code = 'test-code';

  const createComponent = (propsData, slots = {}) => {
    wrapper = shallowMount(CodeBlock, {
      slots,
      propsData,
    });
  };

  it('overwrites the default slot', () => {
    createComponent({}, { default: 'DEFAULT SLOT' });

    expect(wrapper.element).toMatchInlineSnapshot(`
      <pre
        class="code code-block rounded"
      >
        DEFAULT SLOT
      </pre>
    `);
  });

  it('renders with empty code prop', () => {
    createComponent({});

    expect(wrapper.element).toMatchInlineSnapshot(`
      <pre
        class="code code-block rounded"
      >
        <code
          class="gl-block"
        />
      </pre>
    `);
  });

  it('renders code prop when provided', () => {
    createComponent({ code });

    expect(wrapper.element).toMatchInlineSnapshot(`
      <pre
        class="code code-block rounded"
      >
        <code
          class="gl-block"
        >
          test-code
        </code>
      </pre>
    `);
  });

  it('sets maxHeight properly when provided', () => {
    createComponent({ code, maxHeight: '200px' });

    expect(wrapper.element).toMatchInlineSnapshot(`
      <pre
        class="code code-block rounded"
        style="max-height: 200px; overflow-y: auto;"
      >
        <code
          class="gl-block"
        >
          test-code
        </code>
      </pre>
    `);
  });
});
