import { shallowMount } from '@vue/test-utils';
import TerminalComponent from '~/environments/components/environment_terminal_button.vue';

describe('Stop Component', () => {
  let wrapper;
  const terminalPath = '/path';

  const mountWithProps = props => {
    wrapper = shallowMount(TerminalComponent, {
      attachToDocument: true,
      propsData: props,
    });
  };

  beforeEach(() => {
    mountWithProps({ terminalPath });
  });

  describe('computed', () => {
    it('title', () => {
      expect(wrapper.vm.title).toEqual('Terminal');
    });
  });

  it('should render a link to open a web terminal with the provided path', () => {
    expect(wrapper.is('a')).toBe(true);
    expect(wrapper.attributes('title')).toBe('Terminal');
    expect(wrapper.attributes('aria-label')).toBe('Terminal');
    expect(wrapper.attributes('href')).toBe(terminalPath);
  });

  it('should render a non-disabled button', () => {
    expect(wrapper.classes()).not.toContain('disabled');
  });
});
