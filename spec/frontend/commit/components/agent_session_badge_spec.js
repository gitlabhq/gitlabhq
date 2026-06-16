import { GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AgentSessionBadge from '~/commit/components/agent_session_badge.vue';

describe('AgentSessionBadge', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(AgentSessionBadge);
  };

  const findBadge = () => wrapper.findComponent(GlBadge);

  beforeEach(() => {
    createComponent();
  });

  it('renders a badge with the correct props', () => {
    expect(findBadge().props()).toMatchObject({
      icon: 'session-ai',
      variant: 'info',
    });
  });

  it('renders tooltip title and aria-label', () => {
    expect(findBadge().attributes('title')).toBe('Commit authored in a GitLab Duo Agent session');
    expect(findBadge().attributes('aria-label')).toBe('GitLab Duo Agent session');
  });
});
