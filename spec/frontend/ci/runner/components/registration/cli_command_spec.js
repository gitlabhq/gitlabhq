import CliCommand from '~/ci/runner/components/registration/cli_command.vue';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('CliCommand', () => {
  let wrapper;

  const findPre = () => wrapper.find('pre');
  const findCopyBtn = () => wrapper.findComponent(ModalCopyButton);
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
});
