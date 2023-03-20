import CliCommand from '~/ci/runner/components/registration/cli_command.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('CliCommand', () => {
  let wrapper;

  // use .textContent instead of .text() to capture whitespace that's visible in <pre>
  const getPreTextContent = () => wrapper.find('pre').element.textContent;
  const getClipboardText = () => wrapper.findComponent(ClipboardButton).props('text');

  const createComponent = (props) => {
    wrapper = shallowMountExtended(CliCommand, {
      propsData: {
        ...props,
      },
    });
  };

  it('when rendering a command', () => {
    createComponent({
      prompt: '#',
      command: 'echo hi',
    });

    expect(getPreTextContent()).toBe('# echo hi');
    expect(getClipboardText()).toBe('echo hi');
  });

  it('when rendering a multi-line command', () => {
    createComponent({
      prompt: '#',
      command: ['git', ' --version'],
    });

    expect(getPreTextContent()).toBe('# git --version');
    expect(getClipboardText()).toBe('git --version');
  });
});
