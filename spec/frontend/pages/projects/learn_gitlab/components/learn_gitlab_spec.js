import { GlProgressBar } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import LearnGitlab from '~/pages/projects/learn_gitlab/components/learn_gitlab.vue';
import eventHub from '~/invite_members/event_hub';
import { testActions, testSections } from './mock_data';

describe('Learn GitLab', () => {
  let wrapper;
  let inviteMembersOpen = false;

  const createWrapper = () => {
    wrapper = mount(LearnGitlab, {
      propsData: { actions: testActions, sections: testSections, inviteMembersOpen },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    inviteMembersOpen = false;
  });

  it('renders correctly', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders the progress percentage', () => {
    const text = wrapper.find('[data-testid="completion-percentage"]').text();

    expect(text).toBe('22% completed');
  });

  it('renders the progress bar with correct values', () => {
    const progressBar = wrapper.findComponent(GlProgressBar);

    expect(progressBar.attributes('value')).toBe('2');
    expect(progressBar.attributes('max')).toBe('9');
  });

  describe('Invite Members Modal', () => {
    let spy;

    beforeEach(() => {
      spy = jest.spyOn(eventHub, '$emit');
    });

    it('emits openModal', () => {
      inviteMembersOpen = true;

      createWrapper();

      expect(spy).toHaveBeenCalledWith('openModal', {
        mode: 'celebrate',
        inviteeType: 'members',
        source: 'learn-gitlab',
      });
    });

    it('does not emit openModal', () => {
      createWrapper();

      expect(spy).not.toHaveBeenCalled();
    });
  });
});
