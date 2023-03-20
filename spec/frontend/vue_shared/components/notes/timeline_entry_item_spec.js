import { shallowMount } from '@vue/test-utils';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';

describe(`TimelineEntryItem`, () => {
  let wrapper;

  const factory = (options = {}) => {
    wrapper = shallowMount(TimelineEntryItem, {
      ...options,
    });
  };

  it('renders correctly', () => {
    factory();

    expect(wrapper.classes()).toContain('timeline-entry');

    expect(wrapper.find('.timeline-entry-inner').exists()).toBe(true);
  });

  it('accepts default slot', () => {
    const dummyContent = '<p>some content</p>';
    factory({
      slots: {
        default: dummyContent,
      },
    });

    const content = wrapper.find('.timeline-entry-inner :first-child');

    expect(content.html()).toBe(dummyContent);
  });
});
