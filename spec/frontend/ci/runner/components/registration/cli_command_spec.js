import CliCommand from '~/ci/runner/components/registration/cli_command.vue';
import CodeBlockHighlighted from '~/vue_shared/components/code_block_highlighted.vue';
import SimpleCopyButton from '~/vue_shared/components/simple_copy_button.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('CliCommand', () => {
  let wrapper;

  const findPre = () => wrapper.find('pre');
  const findCodeBlock = () => wrapper.findComponent(CodeBlockHighlighted);
  const findCopyBtn = () => wrapper.findComponent(SimpleCopyButton);
  const getPreTextContent = () => findPre().element.textContent; // use .textContent instead of .text() to capture whitespace that's visible in <pre>

  const createComponent = (props) => {
    wrapper = shallowMountExtended(CliCommand, {
      propsData: {
        ...props,
      },
    });
  };

  it('displays a command', () => {
    createComponent({
      prompt: '#',
      command: 'echo hi',
    });

    expect(findPre().attributes('style')).toBe('max-height: 300px;');
    expect(getPreTextContent()).toBe('# echo hi');
    expect(findCopyBtn().props()).toMatchObject({
      title: 'Copy command',
      text: 'echo hi',
    });
  });

  it('displays a multi-line command', () => {
    createComponent({
      prompt: '#',
      command: ['git', ' --version'],
    });

    expect(getPreTextContent()).toBe('# git --version');
    expect(findCopyBtn().props()).toMatchObject({
      text: 'git --version',
    });
  });

  it('displays a custom button title', () => {
    createComponent({
      buttonTitle: 'Copy me!',
    });

    expect(findCopyBtn().props()).toMatchObject({
      title: 'Copy me!',
    });
  });

  it('displays an empty element when command is missing', () => {
    createComponent({
      command: null,
    });

    expect(getPreTextContent()).toBe('');
    expect(findCopyBtn().props('text')).toBe('');
  });

  it('does not render a highlighted code block when no language is set', () => {
    createComponent({
      command: 'echo hi',
    });

    expect(findCodeBlock().exists()).toBe(false);
  });

  describe('when a language is set', () => {
    beforeEach(() => {
      createComponent({
        command: 'gcloud services enable compute.googleapis.com',
        language: 'powershell',
      });
    });

    it('renders a highlighted code block instead of a plain pre', () => {
      expect(findCodeBlock().props()).toMatchObject({
        language: 'powershell',
        code: 'gcloud services enable compute.googleapis.com',
        maxHeight: '300px',
      });
      expect(findPre().exists()).toBe(false);
    });

    it('renders the block in a bordered, padded container', () => {
      expect(findCodeBlock().classes()).toEqual(expect.arrayContaining(['gl-border', 'gl-p-4']));
    });

    it('keeps the copy button', () => {
      expect(findCopyBtn().props()).toMatchObject({
        title: 'Copy command',
        text: 'gcloud services enable compute.googleapis.com',
      });
    });
  });

  it('joins a multi-line command for highlighting', () => {
    createComponent({
      command: ['gcloud', ' --version'],
      language: 'powershell',
    });

    expect(findCodeBlock().props('code')).toBe('gcloud --version');
  });
});
