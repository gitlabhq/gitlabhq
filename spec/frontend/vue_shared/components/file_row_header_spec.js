import { shallowMount } from '@vue/test-utils';
import FileRowHeader from '~/vue_shared/components/file_row_header.vue';

describe('File row header component', () => {
  let vm;

  function createComponent(path) {
    vm = shallowMount(FileRowHeader, {
      propsData: {
        path,
      },
    });
  }

  afterEach(() => {
    vm.destroy();
  });

  it('renders file path', () => {
    createComponent('app/assets');

    expect(vm.element).toMatchSnapshot();
  });

  it('trucates path after 40 characters', () => {
    createComponent('app/assets/javascripts/merge_requests');

    expect(vm.element).toMatchSnapshot();
  });

  it('adds multiple ellipsises after 40 characters', () => {
    createComponent('app/assets/javascripts/merge_requests/widget/diffs/notes');

    expect(vm.element).toMatchSnapshot();
  });
});
