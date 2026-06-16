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
    expect(wrapper.findAllComponents(GlButton)).toHaveLength(0);
  });

  const renderedText = () => wrapper.text().replace(/\s+/g, ' ').trim();

  it('shows the collapsed count in the title when every file is listed', () => {
    createComponent({ total: '10', visible: 4 });

    expect(renderedText()).toContain('6 files are collapsed');
    expect(renderedText()).toContain('To view all changes, download the diff.');
    expect(renderedText()).not.toContain('listed on this page');
  });

  it('titles with the listed count and notes the collapsed count when the diff is truncated', () => {
    createComponent({ total: '10+', visible: 4 });

    expect(renderedText()).toContain('Only the first 10 files are listed on this page');
    expect(renderedText()).toContain('6 of these files are collapsed.');
    expect(renderedText()).not.toContain('10+');
  });

  it('omits the collapsed note when the diff is truncated but nothing is collapsed', () => {
    createComponent({ total: '3+', visible: 3 });

    expect(renderedText()).toContain('Only the first 3 files are listed on this page');
    expect(renderedText()).not.toContain('collapsed');
  });
});
