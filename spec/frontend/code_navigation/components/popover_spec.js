import { shallowMount } from '@vue/test-utils';
import Popover from '~/code_navigation/components/popover.vue';

const MOCK_CODE_DATA = Object.freeze({
  hover: [
    {
      language: 'javascript',
      value: 'console.log',
    },
  ],
  definition_url: 'http://test.com',
});

const MOCK_DOCS_DATA = Object.freeze({
  hover: [
    {
      language: null,
      value: 'console.log',
    },
  ],
  definition_url: 'http://test.com',
});

let wrapper;

function factory(position, data) {
  wrapper = shallowMount(Popover, { propsData: { position, data } });
}

describe('Code navigation popover component', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  it('renders popover', () => {
    factory({ x: 0, y: 0, height: 0 }, MOCK_CODE_DATA);

    expect(wrapper.element).toMatchSnapshot();
  });

  describe('code output', () => {
    it('renders code output', () => {
      factory({ x: 0, y: 0, height: 0 }, MOCK_CODE_DATA);

      expect(wrapper.find({ ref: 'code-output' }).exists()).toBe(true);
      expect(wrapper.find({ ref: 'doc-output' }).exists()).toBe(false);
    });
  });

  describe('documentation output', () => {
    it('renders code output', () => {
      factory({ x: 0, y: 0, height: 0 }, MOCK_DOCS_DATA);

      expect(wrapper.find({ ref: 'code-output' }).exists()).toBe(false);
      expect(wrapper.find({ ref: 'doc-output' }).exists()).toBe(true);
    });
  });
});
