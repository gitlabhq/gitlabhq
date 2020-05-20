import { mount } from '@vue/test-utils';
import DownloadViewer from '~/vue_shared/components/content_viewer/viewers/download_viewer.vue';

describe('DownloadViewer', () => {
  let wrapper;

  it.each`
    path                                          | filePath               | fileSize | renderedName  | renderedSize
    ${'somepath/test.abc'}                        | ${undefined}           | ${1024}  | ${'test.abc'} | ${'1.00 KiB'}
    ${'somepath/test.abc'}                        | ${undefined}           | ${null}  | ${'test.abc'} | ${''}
    ${'data:application/unknown;base64,U0VMRUNU'} | ${'somepath/test.abc'} | ${2048}  | ${'test.abc'} | ${'2.00 KiB'}
  `(
    'renders the file name as "$renderedName" and shows size as "$renderedSize"',
    ({ path, filePath, fileSize, renderedName, renderedSize }) => {
      wrapper = mount(DownloadViewer, {
        propsData: { path, filePath, fileSize },
      });

      const renderedFileInfo = wrapper.find('.file-info').text();

      expect(renderedFileInfo).toContain(renderedName);
      expect(renderedFileInfo).toContain(renderedSize);

      expect(wrapper.find('.btn.btn-default').text()).toContain('Download');
      expect(wrapper.find('.btn.btn-default').element).toHaveAttr('download', 'test.abc');
    },
  );
});
