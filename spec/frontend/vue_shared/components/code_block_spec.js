import { shallowMount } from '@vue/test-utils';
import CodeBlock from '~/vue_shared/components/code_block.vue';

describe('Code Block', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(CodeBlock, {
      propsData: {
        code: 'test-code',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('matches snapshot', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });
});
