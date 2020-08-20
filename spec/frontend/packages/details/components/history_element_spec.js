import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import component from '~/packages/details/components/history_element.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';

describe('History Element', () => {
  let wrapper;
  const defaultProps = {
    icon: 'pencil',
  };

  const mountComponent = () => {
    wrapper = shallowMount(component, {
      propsData: { ...defaultProps },
      stubs: {
        TimelineEntryItem,
      },
      slots: {
        default: '<div data-testid="default-slot"></div>',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findTimelineEntry = () => wrapper.find(TimelineEntryItem);
  const findGlIcon = () => wrapper.find(GlIcon);
  const findDefaultSlot = () => wrapper.find('[data-testid="default-slot"]');

  it('renders the correct markup', () => {
    mountComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('has a default slot', () => {
    mountComponent();

    expect(findDefaultSlot().exists()).toBe(true);
  });
  it('has a timeline entry', () => {
    mountComponent();

    expect(findTimelineEntry().exists()).toBe(true);
  });
  it('has an icon', () => {
    mountComponent();

    const icon = findGlIcon();

    expect(icon.exists()).toBe(true);
    expect(icon.attributes('name')).toBe(defaultProps.icon);
  });
});
