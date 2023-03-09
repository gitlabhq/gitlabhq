import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RelatedLinks from '~/vue_merge_request_widget/components/mr_widget_related_links.vue';

describe('MRWidgetRelatedLinks', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(RelatedLinks, { propsData });
  };

  describe('computed', () => {
    describe('closesText', () => {
      it('returns Closes text for open merge request', () => {
        createComponent({ state: 'open', relatedLinks: {} });

        expect(wrapper.vm.closesText).toBe('Closes issues');
      });

      it('returns correct text for closed merge request', () => {
        createComponent({ state: 'closed', relatedLinks: {} });

        expect(wrapper.vm.closesText).toBe('Did not close');
      });

      it('returns correct tense for merged request', () => {
        createComponent({ state: 'merged', relatedLinks: {} });

        expect(wrapper.vm.closesText).toBe('Closed');
      });
    });
  });

  it('should have only have closing issues text', () => {
    createComponent({
      relatedLinks: {
        closing: '<a href="#">#23</a> and <a>#42</a>',
        closingCount: 2,
      },
    });
    const content = wrapper
      .text()
      .replace(/\n(\s)+/g, ' ')
      .trim();

    expect(content).toContain('Closes issues #23 and #42');
    expect(content).not.toContain('Mentions');
  });

  it('should have only have mentioned issues text', () => {
    createComponent({
      relatedLinks: {
        mentioned: '<a href="#">#7</a>',
        mentionedCount: 1,
      },
    });

    const content = wrapper
      .text()
      .replace(/\n(\s)+/g, ' ')
      .trim();

    expect(content).toContain('Mentions issue #7');
    expect(content).not.toContain('Closes issues');
  });

  it('should have closing and mentioned issues at the same time', () => {
    createComponent({
      relatedLinks: {
        closing: '<a href="#">#7</a>',
        mentioned: '<a href="#">#23</a> and <a>#42</a>',
        closingCount: 1,
        mentionedCount: 2,
      },
    });
    const content = wrapper
      .text()
      .replace(/\n(\s)+/g, ' ')
      .trim();

    expect(content).toContain('Closes issue #7');
    expect(content).toContain('Mentions issues #23 and #42');
  });

  describe('should have correct assign issues link', () => {
    it.each([
      [1, 'Assign yourself to this issue'],
      [2, 'Assign yourself to these issues'],
    ])('when issue count is %s, link displays correct text', (unassignedCount, text) => {
      const assignToMe = '/assign';

      createComponent({
        relatedLinks: { assignToMe, unassignedCount },
      });

      const glLinkWrapper = wrapper.findComponent(GlLink);

      expect(glLinkWrapper.attributes('href')).toBe(assignToMe);
      expect(glLinkWrapper.text()).toBe(text);
    });

    it('when no link is present', () => {
      createComponent({
        relatedLinks: { assignToMe: '#', unassignedCount: 0 },
      });

      expect(wrapper.findComponent(GlLink).exists()).toBe(false);
    });
  });
});
