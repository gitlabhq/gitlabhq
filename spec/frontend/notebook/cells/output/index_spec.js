import { mount } from '@vue/test-utils';
import json from 'test_fixtures/blob/notebook/basic.json';
import Output from '~/notebook/cells/output/index.vue';
import MarkdownOutput from '~/notebook/cells/output/markdown.vue';
import DataframeOutput from '~/notebook/cells/output/dataframe.vue';
import {
  relativeRawPath,
  markdownCellContent,
  outputWithDataframe,
  outputWithDataframeContent,
} from '../../mock_data';

describe('Output component', () => {
  let wrapper;

  const createComponent = (output) => {
    wrapper = mount(Output, {
      provide: { relativeRawPath },
      propsData: {
        outputs: [].concat(output),
        count: 1,
      },
    });
  };

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

      const iframe = wrapper.find('iframe');
      expect(iframe.exists()).toBe(true);
      expect(iframe.element.getAttribute('sandbox')).toBe('');
      expect(iframe.element.getAttribute('srcdoc')).toBe('<p>test</p>');
      expect(iframe.element.getAttribute('scrolling')).toBe('auto');
    });

    it('renders multiple raw HTML outputs', () => {
      const htmlType = json.cells[4];
      createComponent([htmlType.outputs[0], htmlType.outputs[0]]);

      expect(wrapper.findAll('iframe')).toHaveLength(2);
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
      const iframe = wrapper.find('iframe');

      expect(iframe.exists()).toBe(true);
      expect(iframe.element.getAttribute('sandbox')).toBe('');
      expect(iframe.element.getAttribute('srcdoc')).toBe('<svg></svg>');
    });
  });

  describe('Markdown output', () => {
    beforeEach(() => {
      const markdownType = { data: { 'text/markdown': markdownCellContent } };
      createComponent(markdownType);
    });

    it('renders a markdown component', () => {
      expect(wrapper.findComponent(MarkdownOutput).props('rawCode')).toBe(markdownCellContent);
    });
  });

  describe('Dataframe output', () => {
    it('renders DataframeOutput component', () => {
      createComponent(outputWithDataframe);

      expect(wrapper.findComponent(DataframeOutput).props('rawCode')).toBe(
        outputWithDataframeContent.join(''),
      );
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
