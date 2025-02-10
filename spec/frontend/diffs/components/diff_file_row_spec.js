import { shallowMount } from '@vue/test-utils';
import DiffFileRow from '~/diffs/components/diff_file_row.vue';
import FileRowStats from '~/diffs/components/file_row_stats.vue';
import ChangedFileIcon from '~/vue_shared/components/changed_file_icon.vue';
import FileRow from '~/vue_shared/components/file_row.vue';

describe('Diff File Row component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(DiffFileRow, {
      propsData: { ...props },
    });
  };

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

    expect(wrapper.findComponent(FileRow).props()).toEqual(
      expect.objectContaining({
        ...sharedProps,
      }),
    );
  });

  it('renders ChangedFileIcon component', () => {
    createComponent({
      level: 4,
      file: {},
      hideFileStats: false,
      showTooltip: true,
    });

    expect(wrapper.findComponent(ChangedFileIcon).props()).toEqual(
      expect.objectContaining({
        file: {},
        size: 16,
        showTooltip: true,
      }),
    );
  });

  it.each`
    fileType  | isViewed | expected
    ${'blob'} | ${false} | ${'gl-font-bold'}
    ${'blob'} | ${true}  | ${'gl-text-subtle'}
    ${'tree'} | ${false} | ${'gl-text-subtle'}
    ${'tree'} | ${true}  | ${'gl-text-subtle'}
  `(
    'with (fileType="$fileType", isViewed=$isViewed), sets fileClasses="$expected"',
    ({ fileType, isViewed, expected }) => {
      createComponent({
        file: {
          type: fileType,
          id: '#123456789',
        },
        level: 0,
        hideFileStats: false,
        viewedFiles: isViewed ? { '#123456789': true } : {},
      });
      expect(wrapper.findComponent(FileRow).props('fileClasses')).toBe(expected);
    },
  );

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
      expect(wrapper.findComponent(FileRowStats).exists()).toEqual(value);
    });
  });

  it('adds is-active class when currentDiffFileId matches file_hash', () => {
    createComponent({
      level: 0,
      currentDiffFileId: '123',
      file: { fileHash: '123' },
      hideFileStats: false,
    });

    expect(wrapper.classes('is-active')).toBe(true);
  });
});
