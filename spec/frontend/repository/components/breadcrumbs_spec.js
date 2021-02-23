import { GlDropdown } from '@gitlab/ui';
import { shallowMount, RouterLinkStub } from '@vue/test-utils';
import Breadcrumbs from '~/repository/components/breadcrumbs.vue';
import UploadBlobModal from '~/repository/components/upload_blob_modal.vue';

describe('Repository breadcrumbs component', () => {
  let wrapper;

  const factory = (currentPath, extraProps = {}) => {
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
      mocks: { $apollo },
    });
  };

  const findUploadBlobModal = () => wrapper.find(UploadBlobModal);

  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    path                        | linkCount
    ${'/'}                      | ${1}
    ${'app'}                    | ${2}
    ${'app/assets'}             | ${3}
    ${'app/assets/javascripts'} | ${4}
  `('renders $linkCount links for path $path', ({ path, linkCount }) => {
    factory(path);

    expect(wrapper.findAll(RouterLinkStub).length).toEqual(linkCount);
  });

  it('escapes hash in directory path', () => {
    factory('app/assets/javascripts#');

    expect(wrapper.findAll(RouterLinkStub).at(3).props('to')).toEqual(
      '/-/tree/app/assets/javascripts%23',
    );
  });

  it('renders last link as active', () => {
    factory('app/assets');

    expect(wrapper.findAll(RouterLinkStub).at(2).attributes('aria-current')).toEqual('page');
  });

  it('does not render add to tree dropdown when permissions are false', async () => {
    factory('/', { canCollaborate: false });

    wrapper.setData({ userPermissions: { forkProject: false, createMergeRequestIn: false } });

    await wrapper.vm.$nextTick();

    expect(wrapper.find(GlDropdown).exists()).toBe(false);
  });

  it('renders add to tree dropdown when permissions are true', async () => {
    factory('/', { canCollaborate: true });

    wrapper.setData({ userPermissions: { forkProject: true, createMergeRequestIn: true } });

    await wrapper.vm.$nextTick();

    expect(wrapper.find(GlDropdown).exists()).toBe(true);
  });

  describe('renders the upload blob modal', () => {
    beforeEach(() => {
      factory('/', { canEditTree: true });
    });

    it('does not render the modal while loading', () => {
      expect(findUploadBlobModal().exists()).toBe(false);
    });

    it('renders the modal once loaded', async () => {
      wrapper.setData({ $apollo: { queries: { userPermissions: { loading: false } } } });

      await wrapper.vm.$nextTick();

      expect(findUploadBlobModal().exists()).toBe(true);
    });
  });
});
