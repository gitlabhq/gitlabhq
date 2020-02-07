import { shallowMount } from '@vue/test-utils';
import IdeFileRow from '~/ide/components/ide_file_row.vue';
import FileRow from '~/vue_shared/components/file_row.vue';

describe('Ide File Row component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(IdeFileRow, {
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
