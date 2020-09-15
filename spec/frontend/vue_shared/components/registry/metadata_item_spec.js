import { shallowMount } from '@vue/test-utils';
import { GlIcon, GlLink } from '@gitlab/ui';
import component from '~/vue_shared/components/registry/metadata_item.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';

describe('Metadata Item', () => {
  let wrapper;
  const defaultProps = {
    text: 'foo',
  };

  const mountComponent = (propsData = defaultProps) => {
    wrapper = shallowMount(component, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findIcon = () => wrapper.find(GlIcon);
  const findLink = (w = wrapper) => w.find(GlLink);
  const findText = () => wrapper.find('[data-testid="metadata-item-text"]');
  const findTooltipOnTruncate = (w = wrapper) => w.find(TooltipOnTruncate);

  describe.each(['xs', 's', 'm', 'l', 'xl'])('size class', size => {
    const className = `mw-${size}`;

    it(`${size} is assigned correctly to text`, () => {
      mountComponent({ ...defaultProps, size });

      expect(findText().classes()).toContain(className);
    });

    it(`${size} is assigned correctly to link`, () => {
      mountComponent({ ...defaultProps, link: 'foo', size });

      expect(findTooltipOnTruncate().classes()).toContain(className);
    });
  });

  describe('text', () => {
    it('display a proper text', () => {
      mountComponent();

      expect(findText().text()).toBe(defaultProps.text);
    });

    it('uses tooltip_on_truncate', () => {
      mountComponent();

      const tooltip = findTooltipOnTruncate(findText());
      expect(tooltip.exists()).toBe(true);
      expect(tooltip.attributes('title')).toBe(defaultProps.text);
    });
  });

  describe('link', () => {
    it('if a link prop is passed shows a link and hides the text', () => {
      mountComponent({ ...defaultProps, link: 'bar' });

      expect(findLink().exists()).toBe(true);
      expect(findText().exists()).toBe(false);

      expect(findLink().attributes('href')).toBe('bar');
    });

    it('uses tooltip_on_truncate', () => {
      mountComponent({ ...defaultProps, link: 'bar' });

      const tooltip = findTooltipOnTruncate();
      expect(tooltip.exists()).toBe(true);
      expect(tooltip.attributes('title')).toBe(defaultProps.text);
      expect(findLink(tooltip).exists()).toBe(true);
    });

    it('hides the link and shows the test if a link prop is not passed', () => {
      mountComponent();

      expect(findText().exists()).toBe(true);
      expect(findLink().exists()).toBe(false);
    });
  });

  describe('icon', () => {
    it('if a icon prop is passed shows a icon', () => {
      mountComponent({ ...defaultProps, icon: 'pencil' });

      expect(findIcon().exists()).toBe(true);
      expect(findIcon().props('name')).toBe('pencil');
    });

    it('if a icon prop is not passed hides the icon', () => {
      mountComponent();

      expect(findIcon().exists()).toBe(false);
    });
  });
});
