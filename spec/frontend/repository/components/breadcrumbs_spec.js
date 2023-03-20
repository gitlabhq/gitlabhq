import { GlDropdown } from '@gitlab/ui';
import { shallowMount, RouterLinkStub } from '@vue/test-utils';
import { nextTick } from 'vue';
import Breadcrumbs from '~/repository/components/breadcrumbs.vue';
import UploadBlobModal from '~/repository/components/upload_blob_modal.vue';
import NewDirectoryModal from '~/repository/components/new_directory_modal.vue';

const defaultMockRoute = {
  name: 'blobPath',
};

describe('Repository breadcrumbs component', () => {
  let wrapper;

  const factory = (currentPath, extraProps = {}, mockRoute = {}) => {
    const $apollo = {
      queries: {
        userPermissions: {
          loading: true,
        },
      },
    };

    wrapper = shallowMount(Breadcrumbs, {
      propsData: {
        currentPath,
        ...extraProps,
      },
      stubs: {
        RouterLink: RouterLinkStub,
      },
      mocks: {
        $route: {
          defaultMockRoute,
          ...mockRoute,
        },
        $apollo,
      },
    });
  };

  const findUploadBlobModal = () => wrapper.findComponent(UploadBlobModal);
  const findNewDirectoryModal = () => wrapper.findComponent(NewDirectoryModal);

  it.each`
    path                        | linkCount
    ${'/'}                      | ${1}
    ${'app'}                    | ${2}
    ${'app/assets'}             | ${3}
    ${'app/assets/javascripts'} | ${4}
  `('renders $linkCount links for path $path', ({ path, linkCount }) => {
    factory(path);

    expect(wrapper.findAllComponents(RouterLinkStub).length).toEqual(linkCount);
  });

  it.each`
    routeName            | path                        | linkTo
    ${'treePath'}        | ${'app/assets/javascripts'} | ${'/-/tree/app/assets/javascripts'}
    ${'treePathDecoded'} | ${'app/assets/javascripts'} | ${'/-/tree/app/assets/javascripts'}
    ${'blobPath'}        | ${'app/assets/index.js'}    | ${'/-/blob/app/assets/index.js'}
    ${'blobPathDecoded'} | ${'app/assets/index.js'}    | ${'/-/blob/app/assets/index.js'}
  `(
    'links to the correct router path when routeName is $routeName',
    ({ routeName, path, linkTo }) => {
      factory(path, {}, { name: routeName });
      expect(wrapper.findAllComponents(RouterLinkStub).at(3).props('to')).toEqual(linkTo);
    },
  );

  it('escapes hash in directory path', () => {
    factory('app/assets/javascripts#');

    expect(wrapper.findAllComponents(RouterLinkStub).at(3).props('to')).toEqual(
      '/-/tree/app/assets/javascripts%23',
    );
  });

  it('renders last link as active', () => {
    factory('app/assets');

    expect(wrapper.findAllComponents(RouterLinkStub).at(2).attributes('aria-current')).toEqual(
      'page',
    );
  });

  it('does not render add to tree dropdown when permissions are false', async () => {
    factory('/', { canCollaborate: false });

    // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
    // eslint-disable-next-line no-restricted-syntax
    wrapper.setData({ userPermissions: { forkProject: false, createMergeRequestIn: false } });

    await nextTick();

    expect(wrapper.findComponent(GlDropdown).exists()).toBe(false);
  });

  it.each`
    routeName            | isRendered
    ${'blobPath'}        | ${false}
    ${'blobPathDecoded'} | ${false}
    ${'treePath'}        | ${true}
    ${'treePathDecoded'} | ${true}
    ${'projectRoot'}     | ${true}
  `(
    'does render add to tree dropdown $isRendered when route is $routeName',
    ({ routeName, isRendered }) => {
      factory('app/assets/javascripts.js', { canCollaborate: true }, { name: routeName });
      expect(wrapper.findComponent(GlDropdown).exists()).toBe(isRendered);
    },
  );

  it('renders add to tree dropdown when permissions are true', async () => {
    factory('/', { canCollaborate: true });

    // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
    // eslint-disable-next-line no-restricted-syntax
    wrapper.setData({ userPermissions: { forkProject: true, createMergeRequestIn: true } });

    await nextTick();

    expect(wrapper.findComponent(GlDropdown).exists()).toBe(true);
  });

  describe('renders the upload blob modal', () => {
    beforeEach(() => {
      factory('/', { canEditTree: true });
    });

    it('does not render the modal while loading', () => {
      expect(findUploadBlobModal().exists()).toBe(false);
    });

    it('renders the modal once loaded', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({ $apollo: { queries: { userPermissions: { loading: false } } } });

      await nextTick();

      expect(findUploadBlobModal().exists()).toBe(true);
    });
  });

  describe('renders the new directory modal', () => {
    beforeEach(() => {
      factory('some_dir', { canEditTree: true, newDirPath: 'root/master' });
    });
    it('does not render the modal while loading', () => {
      expect(findNewDirectoryModal().exists()).toBe(false);
    });

    it('renders the modal once loaded', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({ $apollo: { queries: { userPermissions: { loading: false } } } });

      await nextTick();

      expect(findNewDirectoryModal().exists()).toBe(true);
      expect(findNewDirectoryModal().props('path')).toBe('root/master/some_dir');
    });
  });
});
