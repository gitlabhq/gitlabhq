import { GlDropdown, GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue/';
import stubChildren from 'helpers/stub_children';
import component from '~/packages/details/components/package_files.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

import { npmFiles, mavenFiles } from '../../mock_data';

describe('Package Files', () => {
  let wrapper;

  const findAllRows = () => wrapper.findAll('[data-testid="file-row"');
  const findFirstRow = () => findAllRows().at(0);
  const findSecondRow = () => findAllRows().at(1);
  const findFirstRowDownloadLink = () => findFirstRow().find('[data-testid="download-link"]');
  const findFirstRowCommitLink = () => findFirstRow().find('[data-testid="commit-link"]');
  const findSecondRowCommitLink = () => findSecondRow().find('[data-testid="commit-link"]');
  const findFirstRowFileIcon = () => findFirstRow().find(FileIcon);
  const findFirstRowCreatedAt = () => findFirstRow().find(TimeAgoTooltip);
  const findFirstActionMenu = () => findFirstRow().findComponent(GlDropdown);
  const findActionMenuDelete = () => findFirstActionMenu().find('[data-testid="delete-file"]');
  const findFirstToggleDetailsButton = () => findFirstRow().findComponent(GlButton);
  const findFirstRowShaComponent = (id) => wrapper.find(`[data-testid="${id}"]`);

  const createComponent = ({ packageFiles = npmFiles, canDelete = true } = {}) => {
    wrapper = mount(component, {
      propsData: {
        packageFiles,
        canDelete,
      },
      stubs: {
        ...stubChildren(component),
        GlTable: false,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('rows', () => {
    it('renders a single file for an npm package', () => {
      createComponent();

      expect(findAllRows()).toHaveLength(1);
    });

    it('renders multiple files for a package that contains more than one file', () => {
      createComponent({ packageFiles: mavenFiles });

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

      expect(findFirstRowDownloadLink().attributes('href')).toBe(npmFiles[0].download_path);
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

      expect(findFirstRowFileIcon().props('fileName')).toBe(npmFiles[0].file_name);
    });
  });

  describe('time-ago tooltip', () => {
    it('exists', () => {
      createComponent();

      expect(findFirstRowCreatedAt().exists()).toBe(true);
    });

    it('has the correct props bound', () => {
      createComponent();

      expect(findFirstRowCreatedAt().props('time')).toBe(npmFiles[0].created_at);
    });
  });

  describe('commit', () => {
    describe('when package file has a pipeline associated', () => {
      it('exists', () => {
        createComponent();

        expect(findFirstRowCommitLink().exists()).toBe(true);
      });

      it('the link points to the commit url', () => {
        createComponent();

        expect(findFirstRowCommitLink().attributes('href')).toBe(
          npmFiles[0].pipelines[0].project.commit_url,
        );
      });

      it('the text is git_commit_message', () => {
        createComponent();

        expect(findFirstRowCommitLink().text()).toBe(npmFiles[0].pipelines[0].git_commit_message);
      });
    });
    describe('when package file has no pipeline associated', () => {
      it('does not exist', () => {
        createComponent({ packageFiles: mavenFiles });

        expect(findFirstRowCommitLink().exists()).toBe(false);
      });
    });

    describe('when only one file lacks an associated pipeline', () => {
      it('renders the commit when it exists and not otherwise', () => {
        createComponent({ packageFiles: [npmFiles[0], mavenFiles[0]] });

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
              expect(id).toBe(npmFiles[0].id);
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
        const [{ ...noShaFile }] = npmFiles;
        noShaFile.file_sha256 = null;
        noShaFile.file_md5 = null;
        noShaFile.file_sha1 = null;
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
        ${'sha-256'} | ${'SHA-256'} | ${'file_sha256'}
        ${'md5'}     | ${'MD5'}     | ${'file_md5'}
        ${'sha-1'}   | ${'SHA-1'}   | ${'file_sha1'}
      `('has a $title row', async ({ selector, title, sha }) => {
        createComponent();

        await showShaFiles();

        expect(findFirstRowShaComponent(selector).props()).toMatchObject({
          title,
          sha,
        });
      });

      it('does not display a row when the data is missing', async () => {
        const [{ ...missingMd5 }] = npmFiles;
        missingMd5.file_md5 = null;

        createComponent({ packageFiles: [missingMd5] });

        await showShaFiles();

        expect(findFirstRowShaComponent('md5').exists()).toBe(false);
      });
    });
  });
});
