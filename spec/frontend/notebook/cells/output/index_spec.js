import { mount } from '@vue/test-utils';
import json from 'test_fixtures/blob/notebook/basic.json';
import Output from '~/notebook/cells/output/index.vue';

describe('Output component', () => {
  let wrapper;

  const createComponent = (output) => {
    wrapper = mount(Output, {
      propsData: {
        outputs: [].concat(output),
        count: 1,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('text output', () => {
    beforeEach(() => {
      const textType = json.cells[2];
      createComponent(textType.outputs[0]);
    });

    it('renders as plain text', () => {
      expect(wrapper.find('pre').exists()).toBe(true);
    });

    it('renders prompt', () => {
      expect(wrapper.find('.prompt span').exists()).toBe(true);
    });
  });

  describe('image output', () => {
    beforeEach(() => {
      const imageType = json.cells[3];
      createComponent(imageType.outputs[0]);
    });

    it('renders as an image', () => {
      expect(wrapper.find('img').exists()).toBe(true);
    });
  });

  describe('html output', () => {
    it('renders raw HTML', () => {
      const htmlType = json.cells[4];
      createComponent(htmlType.outputs[0]);

      expect(wrapper.findAll('p')).toHaveLength(1);
      expect(wrapper.text()).toContain('test');
    });

    it('renders multiple raw HTML outputs', () => {
      const htmlType = json.cells[4];
      createComponent([htmlType.outputs[0], htmlType.outputs[0]]);

      expect(wrapper.findAll('p')).toHaveLength(2);
    });
  });

  describe('LaTeX output', () => {
    it('renders LaTeX', () => {
      const output = {
        data: {
          'text/latex': ['$$F(k) = \\int_{-\\infty}^{\\infty} f(x) e^{2\\pi i k} dx$$'],
          'text/plain': ['<IPython.core.display.Latex object>'],
        },
        metadata: {},
        output_type: 'display_data',
      };
      createComponent(output);

      expect(wrapper.find('.MathJax').exists()).toBe(true);
    });
  });

  describe('svg output', () => {
    beforeEach(() => {
      const svgType = json.cells[5];
      createComponent(svgType.outputs[0]);
    });

    it('renders as an svg', () => {
      expect(wrapper.find('svg').exists()).toBe(true);
    });
  });

  describe('default to plain text', () => {
    beforeEach(() => {
      const unknownType = json.cells[6];
      createComponent(unknownType.outputs[0]);
    });

    it('renders as plain text', () => {
      expect(wrapper.find('pre').exists()).toBe(true);
      expect(wrapper.text()).toContain('testing');
    });

    it('renders prompt', () => {
      expect(wrapper.find('.prompt span').exists()).toBe(true);
    });

    it("renders as plain text when doesn't recognise other types", () => {
      const unknownType = json.cells[7];
      createComponent(unknownType.outputs[0]);

      expect(wrapper.find('pre').exists()).toBe(true);
      expect(wrapper.text()).toContain('testing');
    });
  });
});
