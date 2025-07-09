import { mount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import HiddenFilesWarning from '~/diffs/components/hidden_files_warning.vue';

const defaultProps = {
  total: '10',
  visible: 5,
  plainDiffPath: 'plain-diff-path',
  emailPatchPath: 'email-patch-path',
};

describe('HiddenFilesWarning', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(HiddenFilesWarning, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  it('has a correct plain diff URL', () => {
    createComponent();
    const plainDiffLink = wrapper.findAllComponents(GlButton).at(0);

    expect(plainDiffLink.attributes('href')).toBe(defaultProps.plainDiffPath);
  });

  it('has a correct email patch URL', () => {
    createComponent();
    const emailPatchLink = wrapper.findAllComponents(GlButton).at(1);

    expect(emailPatchLink.attributes('href')).toBe(defaultProps.emailPatchPath);
  });

  it('does not render buttons when links are not provided', () => {
    createComponent({ plainDiffPath: undefined, emailPatchPath: undefined });
    expect(wrapper.findAllComponents(GlButton).length).toBe(0);
  });

  it('has a correct visible/total files text', () => {
    createComponent();
    expect(wrapper.text()).toContain(
      'For a faster browsing experience, only 5 of 10 files are shown. Download one of the files below to see all changes',
    );
  });
});
