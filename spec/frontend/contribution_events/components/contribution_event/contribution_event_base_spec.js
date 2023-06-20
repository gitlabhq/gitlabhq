import { GlAvatarLabeled, GlAvatarLink, GlIcon } from '@gitlab/ui';
import events from 'test_fixtures/controller/users/activity.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

const [event] = events;

describe('ContributionEventBase', () => {
  let wrapper;

  const defaultPropsData = {
    event,
    iconName: 'approval-solid',
    iconClass: 'gl-text-green-500',
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(ContributionEventBase, {
      propsData: defaultPropsData,
      scopedSlots: {
        default: '<div data-testid="default-slot"></div>',
        'additional-info': '<div data-testid="additional-info-slot"></div>',
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders avatar', () => {
    const avatarLink = wrapper.findComponent(GlAvatarLink);

    expect(avatarLink.attributes('href')).toBe(event.author.web_url);
    expect(avatarLink.findComponent(GlAvatarLabeled).attributes()).toMatchObject({
      label: event.author.name,
      sublabel: `@${event.author.username}`,
      src: event.author.avatar_url,
      size: '32',
    });
  });

  it('renders time ago tooltip', () => {
    expect(wrapper.findComponent(TimeAgoTooltip).props('time')).toBe(event.created_at);
  });

  it('renders icon', () => {
    const icon = wrapper.findComponent(GlIcon);

    expect(icon.props('name')).toBe(defaultPropsData.iconName);
    expect(icon.classes()).toContain(defaultPropsData.iconClass);
  });

  it('renders `default` slot', () => {
    expect(wrapper.findByTestId('default-slot').exists()).toBe(true);
  });

  it('renders `additional-info` slot', () => {
    expect(wrapper.findByTestId('additional-info-slot').exists()).toBe(true);
  });
});
