import { GlBadge, GlLink, GlPopover } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';

import WorkItemFeedback from '~/work_items_feedback/components/work_item_feedback.vue';

describe('WorkItemFeedback', () => {
  /** @type {import('@vue/test-utils').Wrapper} */
  let wrapper;
  const userCalloutDismissSpy = jest.fn();

  const title = 'New thing!';
  const content = 'We added a new work items thing, you should be able to see it.';
  const feedbackIssueText = 'Click here to leave us feedback.';
  const feedbackIssue = 'https://link.to.gitlab/issue';
  const featureName = 'the_feature_we_want_feedback_for';

  const createComponent = (shouldShowPopover) => {
    wrapper = shallowMount(WorkItemFeedback, {
      provide: {
        feedbackIssue,
        feedbackIssueText,
        title,
        content,
        featureName,
      },
      stubs: {
        UserCalloutDismisser: makeMockUserCalloutDismisser({
          dismiss: userCalloutDismissSpy,
          shouldShowCallout: shouldShowPopover,
        }),
      },
    });
  };

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findLink = () => findPopover().findComponent(GlLink);

  describe('template', () => {
    beforeEach(() => {
      createComponent(false);
    });
    it('renders a badge', () => {
      expect(findBadge().exists()).toBe(true);
    });
    it('displays the title in the badge', () => {
      expect(findBadge().text()).toContain(title);
    });
    it('renders a popover', () => {
      expect(findPopover().exists()).toBe(true);
    });
    it('displays the content in the popover', () => {
      expect(findPopover().text()).toContain(content);
    });
    it('displays the feedback issue link and text in the popover', () => {
      const link = findLink();
      expect(link.exists()).toBe(true);
      expect(link.text()).toBe(feedbackIssueText);
      expect(link.attributes('href')).toBe(feedbackIssue);
    });
  });

  describe('interaction', () => {
    it('opens by default if the callout has not been dismissed', async () => {
      createComponent(true);

      await nextTick();

      expect(findPopover().props('show')).toBe(true);
    });
    it('triggers the dismissal function when closed', async () => {
      createComponent(true);

      await nextTick();

      findPopover().vm.$emit('close-button-clicked');

      expect(userCalloutDismissSpy).toHaveBeenCalledTimes(1);
    });
    it('is closed by default if the user has dismissed it', async () => {
      createComponent(false);

      await nextTick();

      expect(findPopover().props('show')).toBe(false);
    });
  });
});
