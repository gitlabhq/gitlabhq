import { GlAvatarLink } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import AssigneeAvatars from '~/analytics/analytics_dashboards/components/visualizations/data_table/assignee_avatars.vue';

describe('AssigneeAvatars', () => {
  it('renders an avatar link for each assignee', () => {
    const wrapper = mount(AssigneeAvatars, {
      propsData: {
        nodes: [
          {
            name: 'GitLab',
            webUrl: 'https://gitlab.com/gitlab-org/gitlab',
          },
          {
            name: 'GitLab UI',
            webUrl: 'https://gitlab.com/gitlab-org/gitlab-ui',
          },
        ],
      },
    });

    const links = wrapper.findAllComponents(GlAvatarLink);
    expect(links).toHaveLength(2);
    expect(links.at(0).attributes()).toMatchObject({
      title: 'GitLab',
      href: 'https://gitlab.com/gitlab-org/gitlab',
    });
    expect(links.at(1).attributes()).toMatchObject({
      title: 'GitLab UI',
      href: 'https://gitlab.com/gitlab-org/gitlab-ui',
    });
  });
});
