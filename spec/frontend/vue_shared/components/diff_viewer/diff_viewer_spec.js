import { mount } from '@vue/test-utils';
import { GREEN_BOX_IMAGE_URL, RED_BOX_IMAGE_URL } from 'spec/test_constants';
import DiffViewer from '~/vue_shared/components/diff_viewer/diff_viewer.vue';

describe('DiffViewer', () => {
  const requiredProps = {
    diffMode: 'replaced',
    diffViewerMode: 'image',
    diffFile: {},
    newPath: GREEN_BOX_IMAGE_URL,
    newSha: 'ABC',
    oldPath: RED_BOX_IMAGE_URL,
    oldSha: 'DEF',
  };
  let wrapper;

  function createComponent(propsData) {
    wrapper = mount(DiffViewer, { propsData });
  }

  it('renders image diff', () => {
    window.gon = {
      relative_url_root: '',
    };

    createComponent({ ...requiredProps, projectPath: '' });

    expect(wrapper.find('.deleted img').element.src).toBe(`//-/raw/DEF/${RED_BOX_IMAGE_URL}`);
    expect(wrapper.find('.added img').element.src).toBe(`//-/raw/ABC/${GREEN_BOX_IMAGE_URL}`);
  });

  it('renders fallback download diff display', () => {
    createComponent({
      ...requiredProps,
      diffViewerMode: 'added',
      newPath: 'test.abc',
      oldPath: 'testold.abc',
    });

    expect(wrapper.find('.deleted .file-info').text()).toContain('testold.abc');
    expect(wrapper.find('.deleted .btn.btn-default').text()).toContain('Download');
    expect(wrapper.find('.added .file-info').text()).toContain('test.abc');
    expect(wrapper.find('.added .btn.btn-default').text()).toContain('Download');
  });

  describe('renamed file', () => {
    it.each`
      altViewer
      ${'text'}
      ${'notText'}
    `('renders the renamed component when the alternate viewer is $altViewer', ({ altViewer }) => {
      createComponent({
        ...requiredProps,
        diffFile: {
          content_sha: '',
          view_path: '',
          alternate_viewer: { name: altViewer },
        },
        diffMode: 'renamed',
        diffViewerMode: 'renamed',
        newPath: 'test.abc',
        oldPath: 'testold.abc',
      });

      expect(wrapper.text()).toContain('File renamed with no changes.');
    });
  });

  it('renders mode changed component', () => {
    createComponent({
      ...requiredProps,
      diffMode: 'mode_changed',
      newPath: 'test.abc',
      oldPath: 'testold.abc',
      aMode: '123',
      bMode: '321',
    });

    expect(wrapper.text()).toContain('File mode changed from 123 to 321');
  });
});
