import { GlAvatarLabeled } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ProjectAvatar from '~/analytics/analytics_dashboards/components/visualizations/data_table/project_avatar.vue';

const mockProject = {
  id: 'gid://gitlab/Project/7',
  name: 'Project Seven',
  avatarUrl: 'https://www.gravatar.com/avatar/abc?s=80&d=identicon',
  webUrl: 'https://gitlab.com',
};

describe('ProjectAvatar', () => {
  let wrapper;

  const findLabeledAvatar = () => wrapper.findComponent(GlAvatarLabeled);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ProjectAvatar, {
      propsData: { ...mockProject, ...props },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders the labeled avatar with project metadata', () => {
    expect(findLabeledAvatar().props()).toMatchObject({
      label: 'Project Seven',
      labelLink: 'https://gitlab.com',
      src: 'https://www.gravatar.com/avatar/abc?s=80&d=identicon',
      entityId: 7,
      entityName: 'Project Seven',
      shape: 'rect',
      size: 24,
      fallbackOnError: true,
    });
  });
});
