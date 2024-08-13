import { mountExtended } from 'helpers/vue_test_utils_helper';
import TerminalComponent from '~/environments/components/environment_terminal_button.vue';

describe('Terminal Component', () => {
  let wrapper;
  const terminalPath = '/path';

  const mountWithProps = (props) => {
    wrapper = mountExtended(TerminalComponent, {
      propsData: props,
    });
  };

  beforeEach(() => {
    mountWithProps({ terminalPath });
  });

  it('should render a link to open a web terminal with the provided path', () => {
    const link = wrapper.findByRole('link', { name: 'Terminal' });
    expect(link.attributes('href')).toBe(terminalPath);
  });

  it('should render a non-disabled button', () => {
    expect(wrapper.classes()).not.toContain('disabled');
  });
});
