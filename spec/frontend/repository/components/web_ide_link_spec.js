import WebIdeLink from '~/repository/components/web_ide_link.vue';
import { mount } from '@vue/test-utils';

describe('Web IDE link component', () => {
  let wrapper;

  function createComponent(props) {
    wrapper = mount(WebIdeLink, {
      propsData: { ...props },
      mocks: {
        $route: {
          params: {},
        },
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders link to the Web IDE for a project if only projectPath is given', () => {
    createComponent({ projectPath: 'gitlab-org/gitlab', refSha: 'master' });

    expect(wrapper.attributes('href')).toBe('/-/ide/project/gitlab-org/gitlab/edit/master/-/');
    expect(wrapper.text()).toBe('Web IDE');
  });

  it('renders link to the Web IDE for a project even if both projectPath and forkPath are given', () => {
    createComponent({
      projectPath: 'gitlab-org/gitlab',
      refSha: 'master',
      forkPath: 'my-namespace/gitlab',
    });

    expect(wrapper.attributes('href')).toBe('/-/ide/project/gitlab-org/gitlab/edit/master/-/');
    expect(wrapper.text()).toBe('Web IDE');
  });

  it('renders link to the forked project if it exists and cannot write to the repo', () => {
    createComponent({
      projectPath: 'gitlab-org/gitlab',
      refSha: 'master',
      forkPath: 'my-namespace/gitlab',
      canPushCode: false,
    });

    expect(wrapper.attributes('href')).toBe('/-/ide/project/my-namespace/gitlab/edit/master/-/');
    expect(wrapper.text()).toBe('Edit fork in Web IDE');
  });
});
