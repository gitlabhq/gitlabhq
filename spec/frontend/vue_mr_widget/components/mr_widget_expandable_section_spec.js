import { GlButton, GlCollapse, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MrCollapsibleSection from '~/vue_merge_request_widget/components/mr_widget_expandable_section.vue';

describe('MrWidgetExpanableSection', () => {
  let wrapper;

  const findButton = () => wrapper.find(GlButton);
  const findCollapse = () => wrapper.find(GlCollapse);

  beforeEach(() => {
    wrapper = shallowMount(MrCollapsibleSection, {
      slots: {
        content: '<span>Collapsable Content</span>',
        header: '<span>Header Content</span>',
      },
    });
  });

  it('renders Icon', () => {
    expect(wrapper.find(GlIcon).exists()).toBe(true);
  });

  it('renders header slot', () => {
    expect(wrapper.text()).toContain('Header Content');
  });

  it('renders content slot', () => {
    expect(wrapper.text()).toContain('Collapsable Content');
  });

  describe('when collapse section is closed', () => {
    it('renders button with expand text', () => {
      expect(findButton().text()).toBe('Expand');
    });

    it('renders a collpased section with no visibility', () => {
      const collapse = findCollapse();

      expect(collapse.exists()).toBe(true);
      expect(collapse.attributes('visible')).toBeUndefined();
    });
  });

  describe('when collapse section is open', () => {
    beforeEach(() => {
      findButton().vm.$emit('click');
      return wrapper.vm.$nextTick();
    });

    it('renders button with collapse text', () => {
      const button = findButton();

      expect(button.exists()).toBe(true);
      expect(button.text()).toBe('Collapse');
    });

    it('renders a collpased section with visible content', () => {
      const collapse = findCollapse();

      expect(collapse.exists()).toBe(true);
      expect(collapse.attributes('visible')).toBe('true');
    });
  });
});
