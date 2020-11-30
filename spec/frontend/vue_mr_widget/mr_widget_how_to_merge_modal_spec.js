import { GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MrWidgetHowToMergeModal from '~/vue_merge_request_widget/components/mr_widget_how_to_merge_modal.vue';

describe('MRWidgetHowToMerge', () => {
  let wrapper;

  function mountComponent({ data = {}, props = {} } = {}) {
    wrapper = shallowMount(MrWidgetHowToMergeModal, {
      data() {
        return { ...data };
      },
      propsData: {
        ...props,
      },
      stubs: {},
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  beforeEach(() => {
    mountComponent();
  });

  const findModal = () => wrapper.find(GlModal);
  const findInstructionsFields = () =>
    wrapper.findAll('[ data-testid="how-to-merge-instructions"]');
  const findTipLink = () => wrapper.find(GlSprintf);

  it('renders a modal', () => {
    expect(findModal().exists()).toBe(true);
  });

  it('renders a selection of markdown fields', () => {
    expect(findInstructionsFields().length).toBe(3);
  });

  it('renders a tip including a link to docs when a valid link is present', () => {
    mountComponent({ props: { reviewingDocsPath: '/gitlab-org/help' } });
    expect(findTipLink().exists()).toBe(true);
  });

  it('should not render a tip including a link to docs when a valid link is not present', () => {
    expect(findTipLink().exists()).toBe(false);
  });

  it('should render different instructions based on if the user can merge', () => {
    mountComponent({ props: { canMerge: true } });
    expect(
      findInstructionsFields()
        .at(2)
        .text(),
    ).toContain('git push origin');
  });

  it('should render different instructions based on if the merge is based off a fork', () => {
    mountComponent({ props: { isFork: true } });
    expect(
      findInstructionsFields()
        .at(0)
        .text(),
    ).toContain('FETCH_HEAD');
  });
});
