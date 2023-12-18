import { GlButton, GlCollapse, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import MrCollapsibleSection from '~/vue_merge_request_widget/components/mr_widget_expandable_section.vue';

describe('MrWidgetExpanableSection', () => {
  let wrapper;

  const findButton = () => wrapper.findComponent(GlButton);
  const findCollapse = () => wrapper.findComponent(GlCollapse);

  beforeEach(() => {
    wrapper = shallowMount(MrCollapsibleSection, {
      slots: {
        content: '<span>Collapsable Content</span>',
        header: '<span>Header Content</span>',
      },
    });
  });

  it('renders Icon', () => {
    expect(wrapper.findComponent(GlIcon).exists()).toBe(true);
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
      expect(collapse.props('visible')).toBe(false);
    });
  });

  describe('when collapse section is open', () => {
    beforeEach(async () => {
      findButton().vm.$emit('click');
      await nextTick();
    });

    it('renders button with collapse text', () => {
      const button = findButton();

      expect(button.exists()).toBe(true);
      expect(button.text()).toBe('Collapse');
    });

    it('renders a collpased section with visible content', () => {
      const collapse = findCollapse();

      expect(collapse.exists()).toBe(true);
      expect(collapse.props('visible')).toBe(true);
    });
  });
});
