import { shallowMount } from '@vue/test-utils';
import TimelineEntryItem from '~/rapid_diffs/app/discussions/timeline_entry_item.vue';

describe('TimelineEntryItem', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(TimelineEntryItem, {
      propsData: props,
      slots: {
        avatar: '<div data-testid="avatar-slot">Avatar</div>',
        content: '<div data-testid="content-slot">Content</div>',
      },
    });
  };

  describe('when timelineLayout is false', () => {
    it('renders content slot without timeline layout', () => {
      createComponent({ timelineLayout: false });
      expect(wrapper.find('[data-testid="content-slot"]').exists()).toBe(true);
      expect(wrapper.find('[data-testid="avatar-slot"]').exists()).toBe(false);
    });

    it('does not apply timeline classes', () => {
      createComponent({ timelineLayout: false });
      expect(wrapper.find('li').classes()).not.toContain('gl-relative');
    });
  });

  describe('when timelineLayout is true', () => {
    it('renders both avatar and content slots', () => {
      createComponent({ timelineLayout: true });
      expect(wrapper.find('[data-testid="avatar-slot"]').exists()).toBe(true);
      expect(wrapper.find('[data-testid="content-slot"]').exists()).toBe(true);
    });

    it('applies timeline classes when not last discussion', () => {
      createComponent({ timelineLayout: true, isLastDiscussion: false });
      expect(wrapper.find('li').classes()).toContain('gl-relative');
    });

    it('does not apply timeline classes when last discussion', () => {
      createComponent({ timelineLayout: true, isLastDiscussion: true });
      expect(wrapper.find('li').classes()).not.toContain('gl-relative');
    });
  });
});
