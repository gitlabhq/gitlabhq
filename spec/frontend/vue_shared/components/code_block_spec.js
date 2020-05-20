import { shallowMount } from '@vue/test-utils';
import CodeBlock from '~/vue_shared/components/code_block.vue';

describe('Code Block', () => {
  let wrapper;

  const defaultProps = {
    code: 'test-code',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(CodeBlock, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('with default props', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders correctly', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('with maxHeight set to "200px"', () => {
    beforeEach(() => {
      createComponent({ maxHeight: '200px' });
    });

    it('renders correctly', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });
});
