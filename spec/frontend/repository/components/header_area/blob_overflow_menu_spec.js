import { GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { isLoggedIn } from '~/lib/utils/common_utils';
import BlobOverflowMenu from '~/repository/components/header_area/blob_overflow_menu.vue';
import BlobDefaultActionsGroup from '~/repository/components/header_area/blob_default_actions_group.vue';
import BlobButtonGroup from '~/repository/components/header_area/blob_button_group.vue';
import createRouter from '~/repository/router';
import { blobControlsDataMock, refMock } from '../../mock_data';

jest.mock('~/lib/utils/common_utils', () => ({
  isLoggedIn: jest.fn().mockReturnValue(true),
}));

describe('Blob Overflow Menu', () => {
  let wrapper;

  const projectPath = '/some/project';
  const router = createRouter(projectPath, refMock);

  router.replace({ name: 'blobPath', params: { path: '/some/file.js' } });

  function createComponent(propsData = {}, provided = {}) {
    wrapper = shallowMountExtended(BlobOverflowMenu, {
      router,
      provide: {
        blobInfo: blobControlsDataMock.repository.blobs.nodes[0],
        ...provided,
      },
      propsData: {
        projectPath,
        ...propsData,
      },
      stub: {
        GlDisclosureDropdown,
      },
    });
  }

  const findBlobDefaultActionsGroup = () => wrapper.findComponent(BlobDefaultActionsGroup);
  const findBlobButtonGroup = () => wrapper.findComponent(BlobButtonGroup);

  beforeEach(() => {
    createComponent();
  });

  describe('Default blob actions', () => {
    it('renders BlobDefaultActionsGroup component', () => {
      expect(findBlobDefaultActionsGroup().exists()).toBe(true);
    });

    describe('events', () => {
      it('proxy copy event when overrideCopy is true', () => {
        createComponent({
          overrideCopy: true,
        });

        findBlobDefaultActionsGroup().vm.$emit('copy');
        expect(wrapper.emitted('copy')).toHaveLength(1);
      });

      it('does not proxy copy event when overrideCopy is false', () => {
        createComponent({
          overrideCopy: false,
        });

        findBlobDefaultActionsGroup().vm.$emit('copy');
        expect(wrapper.emitted('copy')).toBeUndefined();
      });
    });
  });

  describe('Blob Button Group', () => {
    it('renders component', () => {
      expect(findBlobButtonGroup().exists()).toBe(true);
    });

    it('does not render when blob is archived', () => {
      createComponent(
        {},
        {
          blobInfo: {
            ...blobControlsDataMock.repository.blobs.nodes[0],
            archived: true,
          },
        },
      );

      expect(findBlobButtonGroup().exists()).toBe(false);
    });

    it('does not render when user is not logged in', () => {
      isLoggedIn.mockImplementationOnce(() => false);
      createComponent();

      expect(findBlobButtonGroup().exists()).toBe(false);
    });
  });
});
