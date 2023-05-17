import { mount } from '@vue/test-utils';
import ErrorOutput from '~/notebook/cells/output/error.vue';
import Prompt from '~/notebook/cells/prompt.vue';
import Markdown from '~/notebook/cells/markdown.vue';
import { errorOutputContent, relativeRawPath } from '../../mock_data';

describe('notebook/cells/output/error.vue', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mount(ErrorOutput, {
      propsData: {
        rawCode: errorOutputContent,
        index: 1,
        count: 2,
      },
      provide: { relativeRawPath },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findPrompt = () => wrapper.findComponent(Prompt);
  const findMarkdown = () => wrapper.findComponent(Markdown);

  it('renders the prompt', () => {
    expect(findPrompt().props()).toMatchObject({ count: 2, showOutput: true, type: 'Out' });
  });

  it('renders the markdown', () => {
    const expectedParsedMarkdown =
      '```error\n' +
      '---------------------------------------------------------------------------\n' +
      'NameError                                 Traceback (most recent call last)\n' +
      '/var/folders/cq/l637k4x13gx6y9p_gfs4c_gc0000gn/T/ipykernel_79203/294318627.py in <module>\n' +
      '----> 1 To\n' +
      '\n' +
      "NameError: name 'To' is not defined\n" +
      '```';

    expect(findMarkdown().props()).toMatchObject({
      cell: { source: [expectedParsedMarkdown] },
      hidePrompt: true,
    });
  });
});
