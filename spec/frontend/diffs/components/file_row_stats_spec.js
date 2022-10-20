import { mount } from '@vue/test-utils';
import FileRowStats from '~/diffs/components/file_row_stats.vue';

describe('Diff file row stats', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mount(FileRowStats, {
      propsData: {
        file: {
          addedLines: 20,
          removedLines: 10,
        },
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders added lines count', () => {
    expect(wrapper.find('.cgreen').text()).toContain('+20');
  });

  it('renders removed lines count', () => {
    expect(wrapper.find('.cred').text()).toContain('-10');
  });
});
