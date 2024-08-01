import { mount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import HiddenFilesWarning from '~/diffs/components/hidden_files_warning.vue';

const propsData = {
  total: '10',
  visible: 5,
  plainDiffPath: 'plain-diff-path',
  emailPatchPath: 'email-patch-path',
};

describe('HiddenFilesWarning', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mount(HiddenFilesWarning, {
      propsData,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('has a correct plain diff URL', () => {
    const plainDiffLink = wrapper.findAllComponents(GlButton).at(0);

    expect(plainDiffLink.attributes('href')).toBe(propsData.plainDiffPath);
  });

  it('has a correct email patch URL', () => {
    const emailPatchLink = wrapper.findAllComponents(GlButton).at(1);

    expect(emailPatchLink.attributes('href')).toBe(propsData.emailPatchPath);
  });

  it('has a correct visible/total files text', () => {
    expect(wrapper.text()).toContain(
      'For a faster browsing experience, only 5 of 10 files are shown. Download one of the files below to see all changes',
    );
  });
});
