import { GlButton, GlIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import DuoLocalSetupSection from '~/pages/projects/shared/permissions/components/duo_local_setup_section.vue';

describe('DuoLocalSetupSection', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(DuoLocalSetupSection);
  };

  const findCards = () => wrapper.findAllByTestId('local-setup-card');

  beforeEach(() => {
    createComponent();
  });

  it('renders the heading and subtitle', () => {
    expect(wrapper.text()).toContain('Local setup');
    expect(wrapper.text()).toContain('Tools you can install to use GitLab Duo.');
  });

  it('renders one card per tool', () => {
    expect(findCards()).toHaveLength(3);
  });

  it.each`
    index | icon           | title                  | description                                                                               | linkText                    | href
    ${0}  | ${'monitor'}   | ${'IDE extensions'}    | ${'VS Code · JetBrains · Visual Studio'}                                                  | ${'Get the extension'}      | ${'/help/editor_extensions/_index.md'}
    ${1}  | ${'terminal'}  | ${'GitLab CLI (glab)'} | ${'Manage merge requests, issues, and pipelines, and run Orbit Local from the terminal.'} | ${'Install glab'}           | ${'/help/editor_extensions/gitlab_cli/_index.md'}
    ${2}  | ${'tanuki-ai'} | ${'GitLab Duo CLI'}    | ${'Run flows and agentic chat from the terminal.'}                                        | ${'Install GitLab Duo CLI'} | ${'/help/user/gitlab_duo_cli/set_up.md'}
  `('renders the $title card', ({ index, icon, title, description, linkText, href }) => {
    const card = findCards().at(index);
    const button = card.findComponent(GlButton);

    expect(card.findComponent(GlIcon).props('name')).toBe(icon);
    expect(card.text()).toContain(title);
    expect(card.text()).toContain(description);
    expect(button.text()).toBe(linkText);
    expect(button.props('icon')).toBe('external-link');
    expect(button.attributes()).toMatchObject({ href, target: '_blank' });
  });
});
