import { GlAlert, GlDropdown, GlButton, GlFormCheckbox, GlLoadingIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { stubComponent } from 'helpers/stub_component';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { s__ } from '~/locale';
import {
  packageFiles as packageFilesMock,
  packageFilesQuery,
} from 'jest/packages_and_registries/package_registry/mock_data';
import PackageFiles from '~/packages_and_registries/package_registry/components/details/package_files.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

import getPackageFiles from '~/packages_and_registries/package_registry/graphql/queries/get_package_files.query.graphql';

Vue.use(VueApollo);

describe('Package Files', () => {
  let wrapper;
  let apolloProvider;

  const findAllRows = () => wrapper.findAllByTestId('file-row');
  const findDeleteSelectedButton = () => wrapper.findByTestId('delete-selected');
  const findFirstRow = () => extendedWrapper(findAllRows().at(0));
  const findSecondRow = () => extendedWrapper(findAllRows().at(1));
  const findPackageFilesAlert = () => wrapper.findComponent(GlAlert);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findFirstRowDownloadLink = () => findFirstRow().findByTestId('download-link');
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
    packageId = '1',
    packageType = 'NPM',
    isLoading = false,
    canDelete = true,
    stubs,
    resolver = jest.fn().mockResolvedValue(packageFilesQuery([file])),
  } = {}) => {
    const requestHandlers = [[getPackageFiles, resolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = mountExtended(PackageFiles, {
      apolloProvider,
      propsData: {
        canDelete,
        isLoading,
        packageId,
        packageType,
      },
      stubs: {
        GlTable: false,
        ...stubs,
      },
    });
  };

  describe('rows', () => {
    it('do not get rendered when query is loading', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findDeleteSelectedButton().props('disabled')).toBe(true);
    });

    it('renders a single file for an npm package', async () => {
      createComponent();
      await waitForPromises();

      expect(findAllRows()).toHaveLength(1);
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders multiple files for a package that contains more than one file', async () => {
      createComponent({ resolver: jest.fn().mockResolvedValue(packageFilesQuery()) });
      await waitForPromises();

      expect(findAllRows()).toHaveLength(2);
    });

    it('does not render gl-alert', async () => {
      createComponent();
      await waitForPromises();

      expect(findPackageFilesAlert().exists()).toBe(false);
    });

    it('renders gl-alert if load fails', async () => {
      createComponent({ resolver: jest.fn().mockRejectedValue() });
      await waitForPromises();

      expect(findPackageFilesAlert().exists()).toBe(true);
      expect(findPackageFilesAlert().text()).toBe(
        s__('PackageRegistry|Something went wrong while fetching package assets.'),
      );
    });
  });

  describe('link', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('exists', () => {
      expect(findFirstRowDownloadLink().exists()).toBe(true);
    });

    it('has the correct attrs bound', () => {
      expect(findFirstRowDownloadLink().attributes('href')).toBe(file.downloadPath);
    });

    it('emits "download-file" event on click', () => {
      findFirstRowDownloadLink().vm.$emit('click');

      expect(wrapper.emitted('download-file')).toEqual([[]]);
    });
  });

  describe('file-icon', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('exists', () => {
      expect(findFirstRowFileIcon().exists()).toBe(true);
    });

    it('has the correct props bound', () => {
      expect(findFirstRowFileIcon().props('fileName')).toBe(file.fileName);
    });
  });

  describe('time-ago tooltip', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('exists', () => {
      expect(findFirstRowCreatedAt().exists()).toBe(true);
    });

    it('has the correct props bound', () => {
      expect(findFirstRowCreatedAt().props('time')).toBe(file.createdAt);
    });
  });

  describe('action menu', () => {
    describe('when the user can delete', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('exists', () => {
        expect(findFirstActionMenu().exists()).toBe(true);
        expect(findFirstActionMenu().props('icon')).toBe('ellipsis_v');
        expect(findFirstActionMenu().props('textSrOnly')).toBe(true);
        expect(findFirstActionMenu().props('text')).toMatchInterpolatedText('More actions');
      });

      describe('menu items', () => {
        describe('delete file', () => {
          it('exists', () => {
            expect(findActionMenuDelete().exists()).toBe(true);
          });

          it('emits a delete event when clicked', async () => {
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

      it('does not exist', async () => {
        createComponent({ canDelete });
        await waitForPromises();

        expect(findFirstActionMenu().exists()).toBe(false);
      });
    });
  });

  describe('multi select', () => {
    describe('when user can delete', () => {
      it('delete selected button exists & is disabled', async () => {
        createComponent();
        await waitForPromises();

        expect(findDeleteSelectedButton().exists()).toBe(true);
        expect(findDeleteSelectedButton().text()).toMatchInterpolatedText('Delete selected');
        expect(findDeleteSelectedButton().props('disabled')).toBe(true);
      });

      it('delete selected button exists & is disabled when isLoading prop is true', async () => {
        createComponent();
        await waitForPromises();
        const first = findAllRowCheckboxes().at(0);

        await first.setChecked(true);

        expect(findDeleteSelectedButton().props('disabled')).toBe(false);

        await wrapper.setProps({ isLoading: true });

        expect(findDeleteSelectedButton().props('disabled')).toBe(true);
        expect(findLoadingIcon().exists()).toBe(true);
      });

      it('checkboxes to select file are visible', async () => {
        createComponent({ resolver: jest.fn().mockResolvedValue(packageFilesQuery()) });
        await waitForPromises();

        expect(findCheckAllCheckbox().exists()).toBe(true);
        expect(findAllRowCheckboxes()).toHaveLength(2);
      });

      it('selecting a checkbox enables delete selected button', async () => {
        createComponent();
        await waitForPromises();

        const first = findAllRowCheckboxes().at(0);

        await first.setChecked(true);

        expect(findDeleteSelectedButton().props('disabled')).toBe(false);
      });

      describe('select all checkbox', () => {
        it('will toggle between selecting all and deselecting all files', async () => {
          const getChecked = () => findAllRowCheckboxes().filter((x) => x.element.checked === true);

          createComponent({ resolver: jest.fn().mockResolvedValue(packageFilesQuery()) });
          await waitForPromises();

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
            resolver: jest.fn().mockResolvedValue(packageFilesQuery()),
            stubs: { GlFormCheckbox: stubComponent(GlFormCheckbox, { props: ['indeterminate'] }) },
          });
          await waitForPromises();

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
        await waitForPromises();

        const first = findAllRowCheckboxes().at(0);

        await first.setChecked(true);

        await findDeleteSelectedButton().trigger('click');

        const [[items]] = wrapper.emitted('delete-files');
        const [{ id }] = items;
        expect(id).toBe(file.id);
      });

      it('emits delete event with both items when all are selected', async () => {
        createComponent({ resolver: jest.fn().mockResolvedValue(packageFilesQuery()) });
        await waitForPromises();

        await findCheckAllCheckbox().setChecked(true);

        await findDeleteSelectedButton().trigger('click');

        const [[items]] = wrapper.emitted('delete-files');
        expect(items).toHaveLength(2);
      });
    });

    describe('when user cannot delete', () => {
      const canDelete = false;

      it('delete selected button does not exist', async () => {
        createComponent({ canDelete });
        await waitForPromises();

        expect(findDeleteSelectedButton().exists()).toBe(false);
      });

      it('checkboxes to select file are not visible', async () => {
        createComponent({ resolver: jest.fn().mockResolvedValue(packageFilesQuery()), canDelete });
        await waitForPromises();

        expect(findCheckAllCheckbox().exists()).toBe(false);
        expect(findAllRowCheckboxes()).toHaveLength(0);
      });
    });
  });

  describe('additional details', () => {
    describe('details toggle button', () => {
      it('exists', async () => {
        createComponent();
        await waitForPromises();

        expect(findFirstToggleDetailsButton().exists()).toBe(true);
      });

      it('is hidden when no details is present', async () => {
        const { ...noShaFile } = file;
        noShaFile.fileSha256 = null;
        noShaFile.fileMd5 = null;
        noShaFile.fileSha1 = null;
        createComponent({ resolver: jest.fn().mockResolvedValue(packageFilesQuery([noShaFile])) });
        await waitForPromises();

        expect(findFirstToggleDetailsButton().exists()).toBe(false);
      });

      it('toggles the details row', async () => {
        createComponent();
        await waitForPromises();

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
        await waitForPromises();

        await showShaFiles();

        expect(findFirstRowShaComponent(selector).props()).toMatchObject({
          title,
          sha,
        });
      });

      it('does not display a row when the data is missing', async () => {
        const { ...missingMd5 } = file;
        missingMd5.fileMd5 = null;

        createComponent({ resolver: jest.fn().mockResolvedValue(packageFilesQuery([missingMd5])) });
        await waitForPromises();

        await showShaFiles();

        expect(findFirstRowShaComponent('md5').exists()).toBe(false);
      });
    });
  });
});
