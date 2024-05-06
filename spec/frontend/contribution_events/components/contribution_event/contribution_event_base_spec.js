import { GlAvatarLabeled, GlAvatarLink, GlIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import TargetLink from '~/contribution_events/components/target_link.vue';
import ResourceParentLink from '~/contribution_events/components/resource_parent_link.vue';
import { eventApproved } from '../../utils';

describe('ContributionEventBase', () => {
  let wrapper;

  const defaultPropsData = {
    event: eventApproved(),
    iconName: 'approval-solid',
    message: 'Approved merge request %{targetLink} in %{resourceParentLink}.',
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(ContributionEventBase, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
      scopedSlots: {
        default: '<div data-testid="default-slot"></div>',
        'additional-info': '<div data-testid="additional-info-slot"></div>',
      },
    });
  };

  it('renders avatar', () => {
    createComponent();

    const avatarLink = wrapper.findComponent(GlAvatarLink);
    const avatarLabeled = avatarLink.findComponent(GlAvatarLabeled);

    expect(avatarLink.attributes('href')).toBe(defaultPropsData.event.author.web_url);
    expect(avatarLabeled.attributes()).toMatchObject({
      src: defaultPropsData.event.author.avatar_url,
      size: '24',
    });
    expect(avatarLabeled.props()).toMatchObject({
      label: defaultPropsData.event.author.name,
      subLabel: `@${defaultPropsData.event.author.username}`,
    });
  });

  it('renders time ago tooltip', () => {
    createComponent();

    expect(wrapper.findComponent(TimeAgoTooltip).props('time')).toBe(
      defaultPropsData.event.created_at,
    );
  });

  it('renders icon', () => {
    createComponent();

    const icon = wrapper.findComponent(GlIcon);

    expect(icon.props('name')).toBe(defaultPropsData.iconName);
  });

  describe('when `message` prop is passed', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders message', () => {
      expect(wrapper.findByTestId('event-body').text()).toBe(
        `Approved merge request ${defaultPropsData.event.target.reference_link_text} in ${defaultPropsData.event.resource_parent.full_name}.`,
      );
    });

    it('renders target link', () => {
      expect(wrapper.findComponent(TargetLink).props('event')).toEqual(defaultPropsData.event);
    });

    it('renders resource parent link', () => {
      expect(wrapper.findComponent(ResourceParentLink).props('event')).toEqual(
        defaultPropsData.event,
      );
    });
  });

  describe('when `message` prop is not passed', () => {
    beforeEach(() => {
      createComponent({ propsData: { message: '' } });
    });

    it('renders `default` slot', () => {
      expect(wrapper.findByTestId('default-slot').exists()).toBe(true);
    });
  });

  it('renders `additional-info` slot', () => {
    createComponent();

    expect(wrapper.findByTestId('additional-info-slot').exists()).toBe(true);
  });
});
