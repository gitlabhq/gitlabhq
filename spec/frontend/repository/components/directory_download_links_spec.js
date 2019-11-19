import { shallowMount } from '@vue/test-utils';
import DirectoryDownloadLinks from '~/repository/components/directory_download_links.vue';

let vm;

function factory(currentPath) {
  vm = shallowMount(DirectoryDownloadLinks, {
    propsData: {
      currentPath,
      links: [{ text: 'zip', path: 'http://test.com/' }, { text: 'tar', path: 'http://test.com/' }],
    },
  });
}

describe('Repository directory download links component', () => {
  afterEach(() => {
    vm.destroy();
  });

  it.each`
    path
    ${'app'}
    ${'app/assets'}
  `('renders downloads links for path $path', ({ path }) => {
    factory(path);

    expect(vm.element).toMatchSnapshot();
  });
});
