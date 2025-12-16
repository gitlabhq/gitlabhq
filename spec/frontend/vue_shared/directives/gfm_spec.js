import { shallowMount } from '@vue/test-utils';
import { gfm } from '~/vue_shared/directives/gfm';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

jest.mock('~/behaviors/markdown/render_gfm');

describe('gfm directive', () => {
  let wrapper;

  const defaultTemplate = '<div v-gfm="markdown"></div>';
  const defaultMarkdown = '**Hello** _world_';

  const createComponent = ({ template = defaultTemplate, markdown = defaultMarkdown } = {}) => {
    const component = {
      directives: {
        gfm,
      },
      props: ['markdown'],
      template,
    };

    wrapper = shallowMount(component, { propsData: { markdown } });
  };

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('renders GFM', () => {
    createComponent();
    expect(renderGFM).toHaveBeenCalledWith(wrapper.element);
    expect(wrapper.text()).toBe('**Hello** _world_');
  });

  it('should sanitize the markdown content', () => {
    const markdown = '**Bold text**<script>alert(1)</script>';
    createComponent({ markdown });

    expect(wrapper.element.querySelector('script')).toBeNull();
  });

  it('should remove any existing children', () => {
    createComponent({
      template: '<div v-gfm="markdown">foo <i>bar</i></div>',
    });

    expect(wrapper.element.textContent).not.toContain('foo');
    expect(wrapper.element.textContent).not.toContain('bar');
  });

  describe('value updates', () => {
    it('should not re-render when value has not changed', () => {
      createComponent();

      wrapper.setProps({ markdown: defaultMarkdown });

      expect(renderGFM).toHaveBeenCalledTimes(1);
    });

    it('should re-render when value changes', async () => {
      createComponent({ markdown: 'Initial' });

      await wrapper.setProps({ markdown: 'Updated' });

      expect(renderGFM).toHaveBeenCalledTimes(2);
      expect(wrapper.text()).toBe('Updated');
    });
  });
});
