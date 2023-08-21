import { shallowMount } from '@vue/test-utils';
import CodeBlock from '~/vue_shared/components/code_block_highlighted.vue';
import waitForPromises from 'helpers/wait_for_promises';

describe('Code Block Highlighted', () => {
  let wrapper;

  const code = 'const foo = 1;';

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(CodeBlock, { propsData });
  };

  it('renders highlighted code if language is supported', async () => {
    createComponent({ code, language: 'javascript' });

    await waitForPromises();

    expect(wrapper.element).toMatchInlineSnapshot(`
      <code-block-stub
        class="highlight"
        code=""
        maxheight="initial"
      >
        <span>
          <span
            class="hljs-keyword"
          >
            const
          </span>
          foo =
          <span
            class="hljs-number"
          >
            1
          </span>
          ;
        </span>
      </code-block-stub>
    `);
  });

  it("renders plain text if language isn't supported", async () => {
    createComponent({ code, language: 'foobar' });
    await waitForPromises();

    expect(wrapper.emitted('error')).toEqual([[expect.any(TypeError)]]);

    expect(wrapper.element).toMatchInlineSnapshot(`
      <code-block-stub
        class="highlight"
        code=""
        maxheight="initial"
      >
        <span>
          const foo = 1;
        </span>
      </code-block-stub>
    `);
  });

  it('renders content as plain text language is not supported', () => {
    const content = '<script>alert("xss")</script>';
    createComponent({ code: content, language: 'foobar' });

    expect(wrapper.text()).toContain(content);
  });
});
