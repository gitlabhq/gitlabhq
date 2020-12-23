import Vue from 'vue';

import mountComponent from 'helpers/vue_mount_component_helper';
import { GREEN_BOX_IMAGE_URL, RED_BOX_IMAGE_URL } from 'spec/test_constants';
import diffViewer from '~/vue_shared/components/diff_viewer/diff_viewer.vue';

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
  let vm;

  function createComponent(props) {
    const DiffViewer = Vue.extend(diffViewer);

    vm = mountComponent(DiffViewer, props);
  }

  afterEach(() => {
    vm.$destroy();
  });

  it('renders image diff', (done) => {
    window.gon = {
      relative_url_root: '',
    };

    createComponent({ ...requiredProps, projectPath: '' });

    setImmediate(() => {
      expect(vm.$el.querySelector('.deleted img').getAttribute('src')).toBe(
        `//-/raw/DEF/${RED_BOX_IMAGE_URL}`,
      );

      expect(vm.$el.querySelector('.added img').getAttribute('src')).toBe(
        `//-/raw/ABC/${GREEN_BOX_IMAGE_URL}`,
      );

      done();
    });
  });

  it('renders fallback download diff display', (done) => {
    createComponent({
      ...requiredProps,
      diffViewerMode: 'added',
      newPath: 'test.abc',
      oldPath: 'testold.abc',
    });

    setImmediate(() => {
      expect(vm.$el.querySelector('.deleted .file-info').textContent.trim()).toContain(
        'testold.abc',
      );

      expect(vm.$el.querySelector('.deleted .btn.btn-default').textContent.trim()).toContain(
        'Download',
      );

      expect(vm.$el.querySelector('.added .file-info').textContent.trim()).toContain('test.abc');
      expect(vm.$el.querySelector('.added .btn.btn-default').textContent.trim()).toContain(
        'Download',
      );

      done();
    });
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

      expect(vm.$el.textContent).toContain('File renamed with no changes.');
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

    expect(vm.$el.textContent).toContain('File mode changed from 123 to 321');
  });
});
