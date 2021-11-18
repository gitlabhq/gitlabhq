import { GlProgressBar, GlAlert } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import LearnGitlab from '~/pages/projects/learn_gitlab/components/learn_gitlab.vue';
import eventHub from '~/invite_members/event_hub';
import { testActions, testSections, testProject } from './mock_data';

describe('Learn GitLab', () => {
  let wrapper;
  let sidebar;
  let inviteMembersOpen = false;

  const createWrapper = () => {
    wrapper = mount(LearnGitlab, {
      propsData: {
        actions: testActions,
        sections: testSections,
        project: testProject,
        inviteMembersOpen,
      },
    });
  };

  beforeEach(() => {
    sidebar = document.createElement('div');
    sidebar.innerHTML = `
    <div class="sidebar-top-level-items">
      <div class="active">
        <div class="count"></div>
      </div>
    </div>
    `;
    document.body.appendChild(sidebar);
    createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    inviteMembersOpen = false;
    sidebar.remove();
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

  describe('when the showSuccessfulInvitationsAlert event is fired', () => {
    const findAlert = () => wrapper.findComponent(GlAlert);

    beforeEach(() => {
      eventHub.$emit('showSuccessfulInvitationsAlert');
    });

    it('displays the successful invitations alert', () => {
      expect(findAlert().exists()).toBe(true);
    });

    it('displays a message with the project name', () => {
      expect(findAlert().text()).toBe(
        "Your team is growing! You've successfully invited new team members to the test-project project.",
      );
    });

    it('modifies the sidebar percentage', () => {
      expect(sidebar.textContent.trim()).toBe('22%');
    });
  });
});
