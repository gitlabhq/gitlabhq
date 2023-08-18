import { mountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEventCommented from '~/contribution_events/components/contribution_event/contribution_event_commented.vue';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import ResourceParentLink from '~/contribution_events/components/resource_parent_link.vue';
import {
  eventCommentedIssue,
  eventCommentedMergeRequest,
  eventCommentedProjectSnippet,
  eventCommentedPersonalSnippet,
  eventCommentedDesign,
  eventCommentedCommit,
} from '../../utils';

describe('ContributionEventCommented', () => {
  let wrapper;

  const createComponent = ({ propsData }) => {
    wrapper = mountExtended(ContributionEventCommented, {
      propsData,
    });
  };

  const findNoteableLink = (event) =>
    wrapper.findByRole('link', { name: event.noteable.reference_link_text });
  const findResourceParentLink = () => wrapper.findComponent(ResourceParentLink);
  const findContributionEventBase = () => wrapper.findComponent(ContributionEventBase);
  const findEventBody = () => wrapper.findByTestId('event-body');

  describe.each`
    event                             | expectedMessage
    ${eventCommentedIssue()}          | ${'Commented on issue'}
    ${eventCommentedMergeRequest()}   | ${'Commented on merge request'}
    ${eventCommentedProjectSnippet()} | ${'Commented on snippet'}
    ${eventCommentedDesign()}         | ${'Commented on design'}
    ${eventCommentedCommit()}         | ${'Commented on commit'}
  `('when event is $event', ({ event, expectedMessage }) => {
    beforeEach(() => {
      createComponent({ propsData: { event } });
    });

    it('renders `ContributionEventBase` with correct props', () => {
      expect(findContributionEventBase().props()).toMatchObject({
        event,
        iconName: 'comment',
      });
    });

    it('renders message', () => {
      expect(findEventBody().text()).toContain(expectedMessage);
    });

    it('renders resource parent link', () => {
      expect(findResourceParentLink().props('event')).toEqual(event);
    });

    it('renders noteable link', () => {
      expect(findNoteableLink(event).attributes('href')).toBe(event.noteable.web_url);
    });

    it('renders first line of comment in markdown', () => {
      expect(wrapper.html()).toContain(event.noteable.first_line_in_markdown);
    });
  });

  describe('when noteable type is a personal snippet', () => {
    const event = eventCommentedPersonalSnippet();

    beforeEach(() => {
      createComponent({ propsData: { event } });
    });

    it('renders `ContributionEventBase` with correct props', () => {
      expect(findContributionEventBase().props()).toMatchObject({
        event,
        iconName: 'comment',
      });
    });

    it('renders message', () => {
      expect(findEventBody().text()).toContain('Commented on snippet');
    });

    it('does not render resource parent link', () => {
      expect(findResourceParentLink().exists()).toBe(false);
    });

    it('does not add `gl-font-monospace` to noteable link', () => {
      expect(findNoteableLink(event).classes()).not.toContain('gl-font-monospace');
    });
  });

  describe('when noteable type is a commit', () => {
    const event = eventCommentedCommit();

    beforeEach(() => {
      createComponent({ propsData: { event } });
    });

    it('adds `gl-font-monospace` to noteable link', () => {
      expect(findNoteableLink(event).classes()).toContain('gl-font-monospace');
    });
  });
});
