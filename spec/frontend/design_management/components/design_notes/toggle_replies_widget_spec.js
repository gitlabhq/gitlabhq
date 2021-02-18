import { GlIcon, GlButton, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ToggleRepliesWidget from '~/design_management/components/design_notes/toggle_replies_widget.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import notes from '../../mock_data/notes';

describe('Toggle replies widget component', () => {
  let wrapper;

  const findToggleWrapper = () => wrapper.find('[data-testid="toggle-comments-wrapper"]');
  const findIcon = () => wrapper.find(GlIcon);
  const findButton = () => wrapper.find(GlButton);
  const findAuthorLink = () => wrapper.find(GlLink);
  const findTimeAgo = () => wrapper.find(TimeAgoTooltip);

  function createComponent(props = {}) {
    wrapper = shallowMount(ToggleRepliesWidget, {
      propsData: {
        collapsed: true,
        replies: notes,
        ...props,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when replies are collapsed', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should not have expanded class', () => {
      expect(findToggleWrapper().classes()).not.toContain('expanded');
    });

    it('should render chevron-right icon', () => {
      expect(findIcon().props('name')).toBe('chevron-right');
    });

    it('should have replies length on button', () => {
      expect(findButton().text()).toBe('2 replies');
    });

    it('should render a link to the last reply author', () => {
      expect(findAuthorLink().exists()).toBe(true);
      expect(findAuthorLink().text()).toBe(notes[1].author.name);
      expect(findAuthorLink().attributes('href')).toBe(notes[1].author.webUrl);
    });

    it('should render correct time ago tooltip', () => {
      expect(findTimeAgo().exists()).toBe(true);
      expect(findTimeAgo().props('time')).toBe(notes[1].createdAt);
    });
  });

  describe('when replies are expanded', () => {
    beforeEach(() => {
      createComponent({ collapsed: false });
    });

    it('should have expanded class', () => {
      expect(findToggleWrapper().classes()).toContain('expanded');
    });

    it('should render chevron-down icon', () => {
      expect(findIcon().props('name')).toBe('chevron-down');
    });

    it('should have Collapse replies text on button', () => {
      expect(findButton().text()).toBe('Collapse replies');
    });

    it('should not have a link to the last reply author', () => {
      expect(findAuthorLink().exists()).toBe(false);
    });

    it('should not render time ago tooltip', () => {
      expect(findTimeAgo().exists()).toBe(false);
    });
  });

  it('should emit toggle event on icon click', () => {
    createComponent();
    findIcon().vm.$emit('click', new MouseEvent('click'));

    expect(wrapper.emitted('toggle')).toHaveLength(1);
  });

  it('should emit toggle event on button click', () => {
    createComponent();
    findButton().vm.$emit('click', new MouseEvent('click'));

    expect(wrapper.emitted('toggle')).toHaveLength(1);
  });
});
