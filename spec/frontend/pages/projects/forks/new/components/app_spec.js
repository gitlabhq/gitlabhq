import { shallowMount } from '@vue/test-utils';
import App from '~/pages/projects/forks/new/components/app.vue';

describe('App component', () => {
  let wrapper;

  const DEFAULT_PROPS = {
    forkIllustration: 'illustrations/project-create-new-sm.svg',
    endpoint: '/some/project-full-path/-/forks/new.json',
    projectFullPath: '/some/project-full-path',
    projectId: '10',
    projectName: 'Project Name',
    projectPath: 'project-name',
    projectDescription: 'some project description',
    projectVisibility: 'private',
    restrictedVisibilityLevels: [],
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(App, {
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays the correct svg illustration', () => {
    expect(wrapper.find('img').attributes('src')).toBe('illustrations/project-create-new-sm.svg');
  });

  it('renders ForkForm component with prop', () => {
    expect(wrapper.props()).toEqual(expect.objectContaining(DEFAULT_PROPS));
  });
});
