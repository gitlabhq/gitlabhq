import { GlBadge, GlLink, GlPopover } from '@gitlab/ui';
import { nextTick } from 'vue';
import ObservabilityFeedback from '~/observability/components/observability_feedback.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';

describe('ObservabilityFeedback', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findLink = () => wrapper.findComponent(GlLink);

  beforeEach(() => {
    wrapper = mountExtended(ObservabilityFeedback);
  });

  it('renders the badge with the correct title', () => {
    expect(findBadge().text()).toBe('Give feedback');
  });

  it('renders the popover content', () => {
    expect(findPopover().text()).toContain(
      'We would love to learn more about your experience with GitLab Observability.',
    );
  });

  it('renders the feedback link with correct text and href', () => {
    expect(findLink().text()).toBe('Give feedback on this experience');
    expect(findLink().attributes('href')).toBe(
      'https://gitlab.com/gitlab-org/embody-team/experimental-observability/gitlab_o11y/-/issues/37',
    );
  });

  it('closes the popover when the feedback link is clicked', async () => {
    await findLink().trigger('click');
    await nextTick();
    expect(findPopover().emitted('close')).toHaveLength(1);
  });
});
