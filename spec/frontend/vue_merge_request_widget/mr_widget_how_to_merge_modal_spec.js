import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MrWidgetHowToMergeModal from '~/vue_merge_request_widget/components/mr_widget_how_to_merge_modal.vue';

describe('MRWidgetHowToMerge', () => {
  let wrapper;

  function mountComponent({ data = {}, props = {} } = {}) {
    wrapper = shallowMount(MrWidgetHowToMergeModal, {
      data() {
        return data;
      },
      propsData: props,
      stubs: {},
    });
  }

  beforeEach(() => {
    mountComponent();
  });

  const findModal = () => wrapper.findComponent(GlModal);
  const findInstructionsFields = () =>
    wrapper.findAll('[ data-testid="how-to-merge-instructions"]');
  const findTipLink = () => wrapper.find("[data-testid='docs-tip']");

  it('renders a modal', () => {
    expect(findModal().exists()).toBe(true);
  });

  it('renders a selection of markdown fields', () => {
    expect(findInstructionsFields().length).toBe(2);
  });

  it('renders a tip including a link to docs when a valid link is present', () => {
    mountComponent({ props: { reviewingDocsPath: '/gitlab-org/help' } });
    expect(findTipLink().exists()).toBe(true);
  });

  it('should not render a tip including a link to docs when a valid link is not present', () => {
    expect(findTipLink().exists()).toBe(false);
  });

  it('should render instructions to push', () => {
    mountComponent({ props: { sourceBranch: 'branch-of-user' } });
    expect(findInstructionsFields().at(1).text()).toContain("git push origin 'branch-of-user'");
  });

  it('should render instructions to push to fork', () => {
    mountComponent({
      props: {
        sourceProjectDefaultUrl: 'git@gitlab.com:contributor/Underscore.git',
        sourceProjectPath: 'Underscore',
        sourceBranch: 'branch-of-user',
        isFork: true,
      },
    });
    expect(findInstructionsFields().at(1).text()).toContain(
      'git push "git@gitlab.com:contributor/Underscore.git" \'Underscore-branch-of-user:branch-of-user\'',
    );
  });

  it('escapes the source branch name shell-secure', () => {
    mountComponent({ props: { sourceBranch: 'branch-of-$USER' } });
    expect(findInstructionsFields().at(0).text()).toContain("'branch-of-$USER'");
  });
});
