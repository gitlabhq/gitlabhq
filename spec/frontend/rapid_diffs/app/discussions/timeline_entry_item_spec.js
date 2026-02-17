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
  });

  describe('when timelineLayout is true', () => {
    it('renders both avatar and content slots', () => {
      createComponent({ timelineLayout: true });
      expect(wrapper.find('[data-testid="avatar-slot"]').exists()).toBe(true);
      expect(wrapper.find('[data-testid="content-slot"]').exists()).toBe(true);
    });
  });
});
