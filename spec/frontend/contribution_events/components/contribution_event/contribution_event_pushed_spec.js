import { mountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEventPushed from '~/contribution_events/components/contribution_event/contribution_event_pushed.vue';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import ResourceParentLink from '~/contribution_events/components/resource_parent_link.vue';
import {
  eventPushedNewBranch,
  eventPushedNewTag,
  eventPushedBranch,
  eventPushedTag,
  eventPushedRemovedBranch,
  eventPushedRemovedTag,
  eventBulkPushedBranch,
} from '../../utils';

describe('ContributionEventPushed', () => {
  let wrapper;

  const createComponent = ({ propsData }) => {
    wrapper = mountExtended(ContributionEventPushed, {
      propsData,
    });
  };

  describe.each`
    event                         | expectedMessage          | expectedIcon
    ${eventPushedNewBranch()}     | ${'Pushed a new branch'} | ${'commit'}
    ${eventPushedNewTag()}        | ${'Pushed a new tag'}    | ${'commit'}
    ${eventPushedBranch()}        | ${'Pushed to branch'}    | ${'commit'}
    ${eventPushedTag()}           | ${'Pushed to tag'}       | ${'commit'}
    ${eventPushedRemovedBranch()} | ${'Deleted branch'}      | ${'remove'}
    ${eventPushedRemovedTag()}    | ${'Deleted tag'}         | ${'remove'}
  `('when event is $event', ({ event, expectedMessage, expectedIcon }) => {
    beforeEach(() => {
      createComponent({ propsData: { event } });
    });

    it('renders `ContributionEventBase` with correct props', () => {
      expect(wrapper.findComponent(ContributionEventBase).props()).toMatchObject({
        event,
        iconName: expectedIcon,
      });
    });

    it('renders message', () => {
      expect(wrapper.findByTestId('event-body').text()).toContain(expectedMessage);
    });

    it('renders resource parent link', () => {
      expect(wrapper.findComponent(ResourceParentLink).props('event')).toEqual(event);
    });
  });

  describe('when ref has a path', () => {
    const event = eventPushedNewBranch();
    const path = '/foo';

    beforeEach(() => {
      createComponent({
        propsData: {
          event: {
            ...event,
            ref: {
              ...event.ref,
              path,
            },
          },
        },
      });
    });

    it('renders ref link', () => {
      expect(wrapper.findByRole('link', { name: event.ref.name }).attributes('href')).toBe(path);
    });
  });

  describe('when ref does not have a path', () => {
    const event = eventPushedRemovedBranch();

    beforeEach(() => {
      createComponent({
        propsData: {
          event,
        },
      });
    });

    it('renders ref name without a link', () => {
      expect(wrapper.findByRole('link', { name: event.ref.name }).exists()).toBe(false);
      expect(wrapper.findByText(event.ref.name).exists()).toBe(true);
    });
  });

  it('renders renders a link to the commit', () => {
    const event = eventPushedNewBranch();
    createComponent({
      propsData: {
        event,
      },
    });

    expect(
      wrapper.findByRole('link', { name: event.commit.truncated_sha }).attributes('href'),
    ).toBe(event.commit.path);
  });

  it('renders commit title', () => {
    const event = eventPushedNewBranch();
    createComponent({
      propsData: {
        event,
      },
    });

    expect(wrapper.findByText(event.commit.title).exists()).toBe(true);
  });

  describe('when multiple commits are pushed', () => {
    const event = eventBulkPushedBranch();
    beforeEach(() => {
      createComponent({
        propsData: {
          event,
        },
      });
    });

    it('renders message', () => {
      expect(wrapper.text()).toContain('…and 4 more commits.');
    });

    it('renders compare link', () => {
      expect(
        wrapper
          .findByRole('link', {
            name: `Compare ${event.commit.from_truncated_sha}…${event.commit.to_truncated_sha}`,
          })
          .attributes('href'),
      ).toBe(event.commit.compare_path);
    });
  });
});
