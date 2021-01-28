import { mount } from '@vue/test-utils';
import { GlButton, GlPopover } from '@gitlab/ui';
import HelpPopover from '~/vue_shared/components/help_popover.vue';

describe('HelpPopover', () => {
  let wrapper;
  const title = 'popover <strong>title</strong>';
  const content = 'popover <b>content</b>';

  const findQuestionButton = () => wrapper.find(GlButton);
  const findPopover = () => wrapper.find(GlPopover);
  const buildWrapper = (options = {}) => {
    wrapper = mount(HelpPopover, {
      propsData: {
        options: {
          title,
          content,
          ...options,
        },
      },
    });
  };

  beforeEach(() => {
    buildWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders a link button with an icon question', () => {
    expect(findQuestionButton().props()).toMatchObject({
      icon: 'question',
      variant: 'link',
    });
    expect(findQuestionButton().attributes().tabindex).toBe('0');
  });

  it('renders popover that uses the question button as target', () => {
    expect(findPopover().props().target()).toBe(findQuestionButton().vm.$el);
  });

  it('triggers popover on hover and focus', () => {
    expect(findPopover().props().triggers).toBe('hover focus');
  });

  it('allows rendering title with HTML tags', () => {
    expect(findPopover().find('strong').exists()).toBe(true);
  });

  it('allows rendering content with HTML tags', () => {
    expect(findPopover().find('b').exists()).toBe(true);
  });

  it('binds other popover options to the popover instance', () => {
    const placement = 'bottom';

    wrapper.destroy();
    buildWrapper({ placement });

    expect(findPopover().props().placement).toBe(placement);
  });
});
