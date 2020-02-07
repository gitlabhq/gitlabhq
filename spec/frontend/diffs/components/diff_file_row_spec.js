import { shallowMount } from '@vue/test-utils';
import DiffFileRow from '~/diffs/components/diff_file_row.vue';
import FileRow from '~/vue_shared/components/file_row.vue';

describe('Diff File Row component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(DiffFileRow, {
      propsData: { ...props },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders file row component', () => {
    createComponent({
      level: 4,
      file: {},
    });
    expect(wrapper.find(FileRow).exists()).toEqual(true);
  });
});
