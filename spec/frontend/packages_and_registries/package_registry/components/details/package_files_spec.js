import { GlDropdown, GlButton } from '@gitlab/ui';
import { nextTick } from 'vue';
import stubChildren from 'helpers/stub_children';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import { packageFiles as packageFilesMock } from 'jest/packages_and_registries/package_registry/mock_data';
import PackageFiles from '~/packages_and_registries/package_registry/components/details/package_files.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

describe('Package Files', () => {
  let wrapper;

  const findAllRows = () => wrapper.findAllByTestId('file-row');
  const findFirstRow = () => extendedWrapper(findAllRows().at(0));
  const findSecondRow = () => extendedWrapper(findAllRows().at(1));
  const findFirstRowDownloadLink = () => findFirstRow().findByTestId('download-link');
  const findFirstRowCommitLink = () => findFirstRow().findByTestId('commit-link');
  const findSecondRowCommitLink = () => findSecondRow().findByTestId('commit-link');
  const findFirstRowFileIcon = () => findFirstRow().findComponent(FileIcon);
  const findFirstRowCreatedAt = () => findFirstRow().findComponent(TimeAgoTooltip);
  const findFirstActionMenu = () => extendedWrapper(findFirstRow().findComponent(GlDropdown));
  const findActionMenuDelete = () => findFirstActionMenu().findByTestId('delete-file');
  const findFirstToggleDetailsButton = () => findFirstRow().findComponent(GlButton);
  const findFirstRowShaComponent = (id) => wrapper.findByTestId(id);

  const files = packageFilesMock();
  const [file] = files;

  const createComponent = ({ packageFiles = [file], canDelete = true } = {}) => {
    wrapper = mountExtended(PackageFiles, {
      provide: { canDelete },
      propsData: {
        packageFiles,
      },
      stubs: {
        ...stubChildren(PackageFiles),
        GlTable: false,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rows', () => {
    it('renders a single file for an npm package', () => {
      createComponent();

      expect(findAllRows()).toHaveLength(1);
    });

    it('renders multiple files for a package that contains more than one file', () => {
      createComponent({ packageFiles: files });

      expect(findAllRows()).toHaveLength(2);
    });
  });

  describe('link', () => {
    it('exists', () => {
      createComponent();

      expect(findFirstRowDownloadLink().exists()).toBe(true);
    });

    it('has the correct attrs bound', () => {
      createComponent();

      expect(findFirstRowDownloadLink().attributes('href')).toBe(file.downloadPath);
    });

    it('emits "download-file" event on click', () => {
      createComponent();

      findFirstRowDownloadLink().vm.$emit('click');

      expect(wrapper.emitted('download-file')).toEqual([[]]);
    });
  });

  describe('file-icon', () => {
    it('exists', () => {
      createComponent();

      expect(findFirstRowFileIcon().exists()).toBe(true);
    });

    it('has the correct props bound', () => {
      createComponent();

      expect(findFirstRowFileIcon().props('fileName')).toBe(file.fileName);
    });
  });

  describe('time-ago tooltip', () => {
    it('exists', () => {
      createComponent();

      expect(findFirstRowCreatedAt().exists()).toBe(true);
    });

    it('has the correct props bound', () => {
      createComponent();

      expect(findFirstRowCreatedAt().props('time')).toBe(file.createdAt);
    });
  });

  describe('commit', () => {
    const withPipeline = {
      ...file,
      pipelines: [
        {
          sha: 'sha',
          id: 1,
          commitPath: 'commitPath',
        },
      ],
    };

    describe('when package file has a pipeline associated', () => {
      it('exists', () => {
        createComponent({ packageFiles: [withPipeline] });

        expect(findFirstRowCommitLink().exists()).toBe(true);
      });

      it('the link points to the commit path', () => {
        createComponent({ packageFiles: [withPipeline] });

        expect(findFirstRowCommitLink().attributes('href')).toBe(
          withPipeline.pipelines[0].commitPath,
        );
      });

      it('the text is the pipeline sha', () => {
        createComponent({ packageFiles: [withPipeline] });

        expect(findFirstRowCommitLink().text()).toBe(withPipeline.pipelines[0].sha);
      });
    });

    describe('when package file has no pipeline associated', () => {
      it('does not exist', () => {
        createComponent();

        expect(findFirstRowCommitLink().exists()).toBe(false);
      });
    });

    describe('when only one file lacks an associated pipeline', () => {
      it('renders the commit when it exists and not otherwise', () => {
        createComponent({ packageFiles: [withPipeline, file] });

        expect(findFirstRowCommitLink().exists()).toBe(true);
        expect(findSecondRowCommitLink().exists()).toBe(false);
      });
    });

    describe('action menu', () => {
      describe('when the user can delete', () => {
        it('exists', () => {
          createComponent();

          expect(findFirstActionMenu().exists()).toBe(true);
        });

        describe('menu items', () => {
          describe('delete file', () => {
            it('exists', () => {
              createComponent();

              expect(findActionMenuDelete().exists()).toBe(true);
            });

            it('emits a delete event when clicked', () => {
              createComponent();

              findActionMenuDelete().vm.$emit('click');

              const [[{ id }]] = wrapper.emitted('delete-file');
              expect(id).toBe(file.id);
            });
          });
        });
      });

      describe('when the user can not delete', () => {
        const canDelete = false;

        it('does not exist', () => {
          createComponent({ canDelete });

          expect(findFirstActionMenu().exists()).toBe(false);
        });
      });
    });
  });

  describe('additional details', () => {
    describe('details toggle button', () => {
      it('exists', () => {
        createComponent();

        expect(findFirstToggleDetailsButton().exists()).toBe(true);
      });

      it('is hidden when no details is present', () => {
        const { ...noShaFile } = file;
        noShaFile.fileSha256 = null;
        noShaFile.fileMd5 = null;
        noShaFile.fileSha1 = null;
        createComponent({ packageFiles: [noShaFile] });

        expect(findFirstToggleDetailsButton().exists()).toBe(false);
      });

      it('toggles the details row', async () => {
        createComponent();

        expect(findFirstToggleDetailsButton().props('icon')).toBe('angle-down');

        findFirstToggleDetailsButton().vm.$emit('click');
        await nextTick();

        expect(findFirstRowShaComponent('sha-256').exists()).toBe(true);
        expect(findFirstToggleDetailsButton().props('icon')).toBe('angle-up');

        findFirstToggleDetailsButton().vm.$emit('click');
        await nextTick();

        expect(findFirstRowShaComponent('sha-256').exists()).toBe(false);
        expect(findFirstToggleDetailsButton().props('icon')).toBe('angle-down');
      });
    });

    describe('file shas', () => {
      const showShaFiles = () => {
        findFirstToggleDetailsButton().vm.$emit('click');
        return nextTick();
      };

      it.each`
        selector     | title        | sha
        ${'sha-256'} | ${'SHA-256'} | ${'fileSha256'}
        ${'md5'}     | ${'MD5'}     | ${'fileMd5'}
        ${'sha-1'}   | ${'SHA-1'}   | ${'be93151dc23ac34a82752444556fe79b32c7a1ad'}
      `('has a $title row', async ({ selector, title, sha }) => {
        createComponent();

        await showShaFiles();

        expect(findFirstRowShaComponent(selector).props()).toMatchObject({
          title,
          sha,
        });
      });

      it('does not display a row when the data is missing', async () => {
        const { ...missingMd5 } = file;
        missingMd5.fileMd5 = null;

        createComponent({ packageFiles: [missingMd5] });

        await showShaFiles();

        expect(findFirstRowShaComponent('md5').exists()).toBe(false);
      });
    });
  });
});
