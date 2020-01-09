import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SuggestionDiffHeader from '~/vue_shared/components/markdown/suggestion_diff_header.vue';

const DEFAULT_PROPS = {
  canApply: true,
  isApplied: false,
  helpPagePath: 'path_to_docs',
};

describe('Suggestion Diff component', () => {
  let wrapper;

  const createComponent = props => {
    wrapper = shallowMount(SuggestionDiffHeader, {
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
      sync: false,
      attachToDocument: true,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findApplyButton = () => wrapper.find('.js-apply-btn');
  const findHeader = () => wrapper.find('.js-suggestion-diff-header');
  const findHelpButton = () => wrapper.find('.js-help-btn');
  const findLoading = () => wrapper.find(GlLoadingIcon);

  it('renders a suggestion header', () => {
    createComponent();

    const header = findHeader();

    expect(header.exists()).toBe(true);
    expect(header.html().includes('Suggested change')).toBe(true);
  });

  it('renders a help button', () => {
    createComponent();

    expect(findHelpButton().exists()).toBe(true);
  });

  it('renders an apply button', () => {
    createComponent();

    const applyBtn = findApplyButton();

    expect(applyBtn.exists()).toBe(true);
    expect(applyBtn.html().includes('Apply suggestion')).toBe(true);
  });

  it('does not render an apply button if `canApply` is set to false', () => {
    createComponent({ canApply: false });

    expect(findApplyButton().exists()).toBe(false);
  });

  describe('when apply suggestion is clicked', () => {
    beforeEach(() => {
      createComponent();

      findApplyButton().vm.$emit('click');
    });

    it('emits apply', () => {
      expect(wrapper.emittedByOrder()).toContainEqual({
        name: 'apply',
        args: [expect.any(Function)],
      });
    });

    it('hides apply button', () => {
      expect(findApplyButton().exists()).toBe(false);
    });

    it('shows loading', () => {
      expect(findLoading().exists()).toBe(true);
      expect(wrapper.text()).toContain('Applying suggestion');
    });

    it('when callback of apply is called, hides loading', () => {
      const [callback] = wrapper.emitted().apply[0];

      callback();

      return wrapper.vm.$nextTick().then(() => {
        expect(findApplyButton().exists()).toBe(true);
        expect(findLoading().exists()).toBe(false);
      });
    });
  });
});
