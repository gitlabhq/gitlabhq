import { shallowMount } from '@vue/test-utils';
import DiffFileRow from '~/diffs/components/diff_file_row.vue';
import FileRow from '~/vue_shared/components/file_row.vue';
import FileRowStats from '~/diffs/components/file_row_stats.vue';
import ChangedFileIcon from '~/vue_shared/components/changed_file_icon.vue';

describe('Diff File Row component', () => {
  let wrapper;

  const createComponent = (props = {}, highlightCurrentDiffRow = false) => {
    wrapper = shallowMount(DiffFileRow, {
      propsData: { ...props },
      provide: {
        glFeatures: { highlightCurrentDiffRow },
      },
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

  it('renders ChangedFileIcon component', () => {
    createComponent({
      level: 4,
      file: {},
      hideFileStats: false,
      showTooltip: true,
    });

    expect(wrapper.find(ChangedFileIcon).props()).toEqual(
      expect.objectContaining({
        file: {},
        size: 16,
        showTooltip: true,
      }),
    );
  });

  it.each`
    features                             | fileType  | isViewed | expected
    ${{ highlightCurrentDiffRow: true }} | ${'blob'} | ${false} | ${'gl-font-weight-bold'}
    ${{}}                                | ${'blob'} | ${true}  | ${''}
    ${{}}                                | ${'tree'} | ${false} | ${''}
    ${{}}                                | ${'tree'} | ${true}  | ${''}
  `(
    'with (features="$features", fileType="$fileType", isViewed=$isViewed), sets fileClasses="$expected"',
    ({ features, fileType, isViewed, expected }) => {
      createComponent(
        {
          file: {
            type: fileType,
            fileHash: '#123456789',
          },
          level: 0,
          hideFileStats: false,
          viewedFiles: isViewed ? { '#123456789': true } : {},
        },
        features.highlightCurrentDiffRow,
      );
      expect(wrapper.find(FileRow).props('fileClasses')).toBe(expected);
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
      expect(wrapper.find(FileRowStats).exists()).toEqual(value);
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
