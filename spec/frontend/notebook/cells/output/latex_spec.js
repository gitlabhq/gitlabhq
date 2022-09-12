import { shallowMount } from '@vue/test-utils';
import LatexOutput from '~/notebook/cells/output/latex.vue';
import Prompt from '~/notebook/cells/prompt.vue';

describe('LaTeX output cell', () => {
  beforeEach(() => {
    window.MathJax = {
      tex2svg: jest.fn((code) => ({ outerHTML: code })),
    };
  });

  const inlineLatex = '$$F(k) = \\int_{-\\infty}^{\\infty} f(x) e^{2\\pi i k} dx$$';
  const count = 12345;

  const createComponent = (rawCode, index) =>
    shallowMount(LatexOutput, {
      propsData: {
        count,
        index,
        rawCode,
      },
    });

  it.each`
    index | expectation
    ${0}  | ${true}
    ${1}  | ${false}
  `('sets `Prompt.show-output` to $expectation when index is $index', ({ index, expectation }) => {
    const wrapper = createComponent(inlineLatex, index);
    const prompt = wrapper.findComponent(Prompt);

    expect(prompt.props().count).toEqual(count);
    expect(prompt.props().showOutput).toEqual(expectation);
  });

  it('strips the `$$` delimter from LaTeX', () => {
    createComponent(inlineLatex, 0);
    expect(window.MathJax.tex2svg).toHaveBeenCalledWith(expect.not.stringContaining('$$'));
  });
});
