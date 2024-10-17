import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import GitlabUniversityCard from '~/ci/pipeline_editor/components/drawer/cards/gitlab_university_card.vue';

describe('GitLab University card', () => {
  let wrapper;
  const GITLAB_UNIVERSITY_LINK = 'https://university.gitlab.com/pages/ci-cd-content';

  const createComponent = () => {
    wrapper = shallowMount(GitlabUniversityCard, {
      stubs: {
        GlSprintf,
      },
    });
  };

  const findGitLabUniversityLink = () => wrapper.findComponent(GlLink);

  beforeEach(() => {
    createComponent();
  });

  it('renders the title', () => {
    expect(wrapper.text()).toContain('Learn CI/CD with GitLab University');
  });

  it('renders the body text', () => {
    expect(wrapper.text()).toContain('Learn how to set up and use GitLab CI/CD');
  });

  it('renders the link', () => {
    expect(findGitLabUniversityLink().exists()).toBe(true);
  });

  it('links to the correct URL', () => {
    expect(findGitLabUniversityLink().attributes().href).toBe(GITLAB_UNIVERSITY_LINK);
  });
});
