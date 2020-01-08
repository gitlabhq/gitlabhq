import { shallowMount } from '@vue/test-utils';
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
    wrapper = shallowMount(HiddenFilesWarning, {
      sync: false,
      propsData,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('has a correct plain diff URL', () => {
    const plainDiffLink = wrapper.findAll('a').wrappers.filter(x => x.text() === 'Plain diff')[0];

    expect(plainDiffLink.attributes('href')).toBe(propsData.plainDiffPath);
  });

  it('has a correct email patch URL', () => {
    const emailPatchLink = wrapper.findAll('a').wrappers.filter(x => x.text() === 'Email patch')[0];

    expect(emailPatchLink.attributes('href')).toBe(propsData.emailPatchPath);
  });

  it('has a correct visible/total files text', () => {
    const filesText = wrapper.find('strong');

    expect(filesText.text()).toBe('5 of 10');
  });
});
