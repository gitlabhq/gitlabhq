import { mount } from '@vue/test-utils';
import { GREEN_BOX_IMAGE_URL } from 'spec/test_constants';
import ContentViewer from '~/vue_shared/components/content_viewer/content_viewer.vue';

jest.mock('~/behaviors/markdown/render_gfm');

describe('ContentViewer', () => {
  let wrapper;

  it.each`
    path                   | type          | selector           | viewer
    ${GREEN_BOX_IMAGE_URL} | ${'image'}    | ${'img'}           | ${'<image-viewer>'}
    ${'myfile.md'}         | ${'markdown'} | ${'.md-previewer'} | ${'<markdown-viewer>'}
    ${'myfile.abc'}        | ${undefined}  | ${'[download]'}    | ${'<download-viewer>'}
  `('renders $viewer when file type="$type"', ({ path, type, selector }) => {
    wrapper = mount(ContentViewer, {
      propsData: { path, fileSize: 1024, type },
    });

    expect(wrapper.find(selector).exists()).toBe(true);
  });
});
