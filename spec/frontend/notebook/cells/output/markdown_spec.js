import { mount } from '@vue/test-utils';
import MarkdownOutput from '~/notebook/cells/output/markdown.vue';
import Prompt from '~/notebook/cells/prompt.vue';
import Markdown from '~/notebook/cells/markdown.vue';
import { relativeRawPath, markdownCellContent } from '../../mock_data';

describe('markdown output cell', () => {
  let wrapper;

  const createComponent = ({ count = 0, index = 0 } = {}) => {
    wrapper = mount(MarkdownOutput, {
      provide: { relativeRawPath },
      propsData: {
        rawCode: markdownCellContent,
        count,
        index,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findPrompt = () => wrapper.findComponent(Prompt);
  const findMarkdown = () => wrapper.findComponent(Markdown);

  it.each`
    index | count | showOutput
    ${0}  | ${1}  | ${true}
    ${1}  | ${2}  | ${false}
    ${2}  | ${3}  | ${false}
  `('renders a prompt', ({ index, count, showOutput }) => {
    createComponent({ count, index });
    expect(findPrompt().props()).toMatchObject({ count, showOutput, type: 'Out' });
  });

  it('renders a Markdown component', () => {
    expect(findMarkdown().props()).toMatchObject({
      cell: { source: markdownCellContent },
      hidePrompt: true,
    });
  });
});
