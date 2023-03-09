import { GlDropdown, GlButton, GlFormCheckbox } from '@gitlab/ui';
import { nextTick } from 'vue';
import { stubComponent } from 'helpers/stub_component';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import { packageFiles as packageFilesMock } from 'jest/packages_and_registries/package_registry/mock_data';
import PackageFiles from '~/packages_and_registries/package_registry/components/details/package_files.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

describe('Package Files', () => {
  let wrapper;

  const findAllRows = () => wrapper.findAllByTestId('file-row');
  const findDeleteSelectedButton = () => wrapper.findByTestId('delete-selected');
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
  const findCheckAllCheckbox = () => wrapper.findByTestId('package-files-checkbox-all');
  const findAllRowCheckboxes = () => wrapper.findAllByTestId('package-files-checkbox');

  const files = packageFilesMock();
  const [file] = files;

  const createComponent = ({
    packageFiles = [file],
    isLoading = false,
    canDelete = true,
    stubs,
  } = {}) => {
    wrapper = mountExtended(PackageFiles, {
      propsData: {
        canDelete,
        isLoading,
        packageFiles,
      },
      stubs: {
        GlTable: false,
        ...stubs,
      },
    });
  };

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
  });

  describe('action menu', () => {
    describe('when the user can delete', () => {
      it('exists', () => {
        createComponent();

        expect(findFirstActionMenu().exists()).toBe(true);
        expect(findFirstActionMenu().props('icon')).toBe('ellipsis_v');
        expect(findFirstActionMenu().props('textSrOnly')).toBe(true);
        expect(findFirstActionMenu().props('text')).toMatchInterpolatedText('More actions');
      });

      describe('menu items', () => {
        describe('delete file', () => {
          it('exists', () => {
            createComponent();

            expect(findActionMenuDelete().exists()).toBe(true);
          });

          it('emits a delete event when clicked', async () => {
            createComponent();

            await findActionMenuDelete().trigger('click');

            const [[items]] = wrapper.emitted('delete-files');
            const [{ id }] = items;
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

  describe('multi select', () => {
    describe('when user can delete', () => {
      it('delete selected button exists & is disabled', () => {
        createComponent();

        expect(findDeleteSelectedButton().exists()).toBe(true);
        expect(findDeleteSelectedButton().text()).toMatchInterpolatedText('Delete selected');
        expect(findDeleteSelectedButton().props('disabled')).toBe(true);
      });

      it('delete selected button exists & is disabled when isLoading prop is true', () => {
        createComponent({ isLoading: true });

        expect(findDeleteSelectedButton().props('disabled')).toBe(true);
      });

      it('checkboxes to select file are visible', () => {
        createComponent({ packageFiles: files });

        expect(findCheckAllCheckbox().exists()).toBe(true);
        expect(findAllRowCheckboxes()).toHaveLength(2);
      });

      it('selecting a checkbox enables delete selected button', async () => {
        createComponent();

        const first = findAllRowCheckboxes().at(0);

        await first.setChecked(true);

        expect(findDeleteSelectedButton().props('disabled')).toBe(false);
      });

      describe('select all checkbox', () => {
        it('will toggle between selecting all and deselecting all files', async () => {
          const getChecked = () => findAllRowCheckboxes().filter((x) => x.element.checked === true);

          createComponent({ packageFiles: files });

          expect(getChecked()).toHaveLength(0);

          await findCheckAllCheckbox().setChecked(true);

          expect(getChecked()).toHaveLength(files.length);

          await findCheckAllCheckbox().setChecked(false);

          expect(getChecked()).toHaveLength(0);
        });

        it('will toggle the indeterminate state when some but not all files are selected', async () => {
          const expectIndeterminateState = (state) =>
            expect(findCheckAllCheckbox().props('indeterminate')).toBe(state);

          createComponent({
            packageFiles: files,
            stubs: { GlFormCheckbox: stubComponent(GlFormCheckbox, { props: ['indeterminate'] }) },
          });

          expectIndeterminateState(false);

          await findSecondRow().trigger('click');

          expectIndeterminateState(true);

          await findSecondRow().trigger('click');

          expectIndeterminateState(false);

          findCheckAllCheckbox().trigger('click');

          expectIndeterminateState(false);

          await findSecondRow().trigger('click');

          expectIndeterminateState(true);
        });
      });

      it('emits a delete event when selected', async () => {
        createComponent();

        const first = findAllRowCheckboxes().at(0);

        await first.setChecked(true);

        await findDeleteSelectedButton().trigger('click');

        const [[items]] = wrapper.emitted('delete-files');
        const [{ id }] = items;
        expect(id).toBe(file.id);
      });

      it('emits delete event with both items when all are selected', async () => {
        createComponent({ packageFiles: files });

        await findCheckAllCheckbox().setChecked(true);

        await findDeleteSelectedButton().trigger('click');

        const [[items]] = wrapper.emitted('delete-files');
        expect(items).toHaveLength(2);
      });
    });

    describe('when user cannot delete', () => {
      const canDelete = false;

      it('delete selected button does not exist', () => {
        createComponent({ canDelete });

        expect(findDeleteSelectedButton().exists()).toBe(false);
      });

      it('checkboxes to select file are not visible', () => {
        createComponent({ packageFiles: files, canDelete });

        expect(findCheckAllCheckbox().exists()).toBe(false);
        expect(findAllRowCheckboxes()).toHaveLength(0);
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

        expect(findFirstToggleDetailsButton().props('icon')).toBe('chevron-down');

        findFirstToggleDetailsButton().vm.$emit('click');
        await nextTick();

        expect(findFirstRowShaComponent('sha-256').exists()).toBe(true);
        expect(findFirstToggleDetailsButton().props('icon')).toBe('chevron-up');

        findFirstToggleDetailsButton().vm.$emit('click');
        await nextTick();

        expect(findFirstRowShaComponent('sha-256').exists()).toBe(false);
        expect(findFirstToggleDetailsButton().props('icon')).toBe('chevron-down');
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
