import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import component from '~/vue_shared/components/settings/settings_block.vue';

describe('Settings Block', () => {
  let wrapper;

  const mountComponent = (propsData) => {
    wrapper = shallowMount(component, {
      propsData,
      slots: {
        title: '<div data-testid="title-slot"></div>',
        description: '<div data-testid="description-slot"></div>',
        default: '<div data-testid="default-slot"></div>',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findDefaultSlot = () => wrapper.find('[data-testid="default-slot"]');
  const findTitleSlot = () => wrapper.find('[data-testid="title-slot"]');
  const findDescriptionSlot = () => wrapper.find('[data-testid="description-slot"]');
  const findExpandButton = () => wrapper.find(GlButton);

  it('renders the correct markup', () => {
    mountComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('has a default slot', () => {
    mountComponent();

    expect(findDefaultSlot().exists()).toBe(true);
  });

  it('has a title slot', () => {
    mountComponent();

    expect(findTitleSlot().exists()).toBe(true);
  });

  it('has a description slot', () => {
    mountComponent();

    expect(findDescriptionSlot().exists()).toBe(true);
  });

  describe('slide animation behaviour', () => {
    it('is animated by default', () => {
      mountComponent();

      expect(wrapper.classes('no-animate')).toBe(false);
    });

    it.each`
      slideAnimated | noAnimatedClass
      ${true}       | ${false}
      ${false}      | ${true}
    `(
      'sets the correct state when slideAnimated is $slideAnimated',
      ({ slideAnimated, noAnimatedClass }) => {
        mountComponent({ slideAnimated });

        expect(wrapper.classes('no-animate')).toBe(noAnimatedClass);
      },
    );
  });

  describe('expanded behaviour', () => {
    it('is collapsed by default', () => {
      mountComponent();

      expect(wrapper.classes('expanded')).toBe(false);
    });

    it('adds expanded class when the expand button is clicked', async () => {
      mountComponent();

      expect(wrapper.classes('expanded')).toBe(false);
      expect(findExpandButton().text()).toBe('Expand');

      await findExpandButton().vm.$emit('click');

      expect(wrapper.classes('expanded')).toBe(true);
      expect(findExpandButton().text()).toBe('Collapse');
    });

    it('is expanded when `defaultExpanded` is true no matter what', async () => {
      mountComponent({ defaultExpanded: true });

      expect(wrapper.classes('expanded')).toBe(true);

      await findExpandButton().vm.$emit('click');

      expect(wrapper.classes('expanded')).toBe(true);

      await findExpandButton().vm.$emit('click');

      expect(wrapper.classes('expanded')).toBe(true);
    });
  });
});
