import { GlProgressBar, GlAlert } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Cookies from 'js-cookie';
import LearnGitlab from '~/pages/projects/learn_gitlab/components/learn_gitlab.vue';
import eventHub from '~/invite_members/event_hub';
import { INVITE_MODAL_OPEN_COOKIE } from '~/pages/projects/learn_gitlab/constants';
import { testActions, testSections, testProject } from './mock_data';

describe('Learn GitLab', () => {
  let wrapper;
  let sidebar;

  const createWrapper = () => {
    wrapper = mount(LearnGitlab, {
      propsData: {
        actions: testActions,
        sections: testSections,
        project: testProject,
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
    let cookieSpy;

    beforeEach(() => {
      spy = jest.spyOn(eventHub, '$emit');
      cookieSpy = jest.spyOn(Cookies, 'remove');
    });

    afterEach(() => {
      Cookies.remove(INVITE_MODAL_OPEN_COOKIE);
    });

    it('emits openModal', () => {
      Cookies.set(INVITE_MODAL_OPEN_COOKIE, true);

      createWrapper();

      expect(spy).toHaveBeenCalledWith('openModal', {
        mode: 'celebrate',
        source: 'learn-gitlab',
      });
      expect(cookieSpy).toHaveBeenCalledWith(INVITE_MODAL_OPEN_COOKIE);
    });

    it('does not emit openModal when cookie is not set', () => {
      createWrapper();

      expect(spy).not.toHaveBeenCalled();
      expect(cookieSpy).toHaveBeenCalledWith(INVITE_MODAL_OPEN_COOKIE);
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
