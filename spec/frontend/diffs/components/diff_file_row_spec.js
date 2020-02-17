import { shallowMount } from '@vue/test-utils';
import DiffFileRow from '~/diffs/components/diff_file_row.vue';
import FileRow from '~/vue_shared/components/file_row.vue';
import FileRowStats from '~/diffs/components/file_row_stats.vue';

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
    const sharedProps = {
      level: 4,
      file: {},
    };

    const diffFileRowProps = {
      hideFileStats: false,
    };

    createComponent({
      ...sharedProps,
      ...diffFileRowProps,
    });

    expect(wrapper.find(FileRow).props()).toEqual(
      expect.objectContaining({
        ...sharedProps,
      }),
    );
  });

  describe('FileRowStats components', () => {
    it.each`
      type      | hideFileStats | value    | desc
      ${'blob'} | ${false}      | ${true}  | ${'is shown if file type is blob'}
      ${'tree'} | ${false}      | ${false} | ${'is hidden if file is not blob'}
      ${'blob'} | ${true}       | ${false} | ${'is hidden if hideFileStats is true'}
    `('$desc', ({ type, value, hideFileStats }) => {
      createComponent({
        level: 4,
        file: {
          type,
        },
        hideFileStats,
      });
      expect(wrapper.find(FileRowStats).exists()).toEqual(value);
    });
  });
});
