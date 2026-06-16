import { shallowMount } from '@vue/test-utils';
import BlobContentViewer from '~/repository/components/blob_content_viewer.vue';
import BlobPage from '~/repository/pages/blob.vue';

jest.mock('~/repository/utils/dom');

describe('Repository blob page component', () => {
  let wrapper;

  const findBlobContentViewer = () => wrapper.findComponent(BlobContentViewer);

  function factory(propsData = {}, routePath = 'file.js') {
    wrapper = shallowMount(BlobPage, {
      propsData: {
        projectPath: 'some/path',
        ...propsData,
      },
      mocks: {
        $route: {
          params: { path: routePath },
        },
      },
    });
  }

  it('has a Blob Content Viewer component', () => {
    factory();
    expect(findBlobContentViewer().exists()).toBe(true);
  });

  it('passes props to BlobContentViewer', () => {
    factory({ projectPath: 'gitlab-org/gitlab', refType: 'heads' }, 'README.md');

    expect(findBlobContentViewer().props('path')).toBe('README.md');
    expect(findBlobContentViewer().props('projectPath')).toBe('gitlab-org/gitlab');
    expect(findBlobContentViewer().props('refType')).toBe('heads');
  });

  it('uses computedPath from mixin to get path from route', () => {
    factory({}, 'src/components/active.vue');

    expect(findBlobContentViewer().props('path')).toBe('src/components/active.vue');
  });
});
