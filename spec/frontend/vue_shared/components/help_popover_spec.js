import { GlButton, GlPopover } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import HelpPopover from '~/vue_shared/components/help_popover.vue';

describe('HelpPopover', () => {
  let wrapper;
  const title = 'popover <strong>title</strong>';
  const content = 'popover <b>content</b>';

  const findQuestionButton = () => wrapper.findComponent(GlButton);
  const findPopover = () => wrapper.findComponent(GlPopover);

  const createComponent = ({ props, ...opts } = {}) => {
    wrapper = mount(HelpPopover, {
      propsData: {
        options: {
          title,
          content,
        },
        ...props,
      },
      ...opts,
    });
  };

  describe('with title and content', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a link button with an icon question', () => {
      expect(findQuestionButton().props()).toMatchObject({
        icon: 'question-o',
        variant: 'link',
      });
    });

    it('renders popover that uses the question button as target', () => {
      expect(findPopover().props().target()).toBe(findQuestionButton().vm.$el);
    });

    it('shows title and content', () => {
      expect(findPopover().html()).toContain(title);
      expect(findPopover().html()).toContain(content);
    });

    it('allows rendering title with HTML tags', () => {
      expect(findPopover().find('strong').exists()).toBe(true);
    });

    it('allows rendering content with HTML tags', () => {
      expect(findPopover().find('b').exists()).toBe(true);
    });
  });

  describe('aria label', () => {
    it('renders default "Help" label', () => {
      createComponent();

      expect(findQuestionButton().attributes('aria-label')).toBe('Help');
    });

    it('renders custom label', () => {
      createComponent({
        props: {
          ariaLabel: 'Learn more',
        },
      });

      expect(findQuestionButton().attributes('aria-label')).toBe('Learn more');
    });
  });

  describe('without title', () => {
    beforeEach(() => {
      createComponent({
        props: {
          options: {
            title: null,
            content,
          },
        },
      });
    });

    it('does not show title', () => {
      expect(findPopover().html()).not.toContain(title);
    });

    it('shows content', () => {
      expect(findPopover().html()).toContain(content);
    });
  });

  describe('with trigger classes', () => {
    it.each`
      triggerClass
      ${'class-a class-b'}
      ${['class-a', 'class-b']}
      ${{ 'class-a': true, 'class-b': true }}
    `('renders button with classes given $triggerClass', ({ triggerClass }) => {
      createComponent({
        props: { triggerClass },
      });

      expect(findQuestionButton().classes('class-a')).toBe(true);
      expect(findQuestionButton().classes('class-b')).toBe(true);
    });
  });

  describe('with other options', () => {
    const placement = 'bottom';

    beforeEach(() => {
      createComponent({
        props: {
          options: {
            placement,
          },
        },
      });
    });

    it('options bind to the popover', () => {
      expect(findPopover().props().placement).toBe(placement);
    });
  });

  describe('with alternative icon', () => {
    beforeEach(() => {
      createComponent({
        props: {
          icon: 'information-o',
        },
      });
    });

    it('uses the given icon', () => {
      expect(findQuestionButton().props('icon')).toBe('information-o');
    });
  });

  describe('with alternative aria label', () => {
    beforeEach(() => {
      createComponent({
        props: {
          icon: 'information-o',
        },
      });
    });

    it('uses the given icon', () => {
      expect(findQuestionButton().props('icon')).toBe('information-o');
    });
  });

  describe('with custom slots', () => {
    const titleSlot = '<h1>title</h1>';
    const defaultSlot = '<strong>content</strong>';

    beforeEach(() => {
      createComponent({
        slots: {
          title: titleSlot,
          default: defaultSlot,
        },
      });
    });

    it('shows title slot', () => {
      expect(findPopover().html()).toContain(titleSlot);
    });

    it('shows default content slot', () => {
      expect(findPopover().html()).toContain(defaultSlot);
    });

    it('overrides title and content from options', () => {
      expect(findPopover().html()).not.toContain(title);
      expect(findPopover().html()).toContain(content);
    });
  });
});
