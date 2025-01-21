import { GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BlobOverflowMenu from '~/repository/components/header_area/blob_overflow_menu.vue';
import BlobDefaultActionsGroup from '~/repository/components/header_area/blob_default_actions_group.vue';
import createRouter from '~/repository/router';
import { blobControlsDataMock, refMock } from '../../mock_data';

describe('Blob Overflow Menu', () => {
  let wrapper;

  const projectPath = '/some/project';
  const router = createRouter(projectPath, refMock);

  router.replace({ name: 'blobPath', params: { path: '/some/file.js' } });

  function createComponent(propsData = {}, provided = {}) {
    wrapper = shallowMountExtended(BlobOverflowMenu, {
      router,
      provide: {
        ...provided,
      },
      propsData: {
        path: blobControlsDataMock.repository.blobs.nodes[0].path,
        rawPath: blobControlsDataMock.repository.blobs.nodes[0].rawPath,
        projectPath,
        richViewer: blobControlsDataMock.repository.blobs.nodes[0].richViewer,
        simpleViewer: blobControlsDataMock.repository.blobs.nodes[0].simpleViewer,
        name: blobControlsDataMock.repository.blobs.nodes[0].name,
        isBinary: blobControlsDataMock.repository.blobs.nodes[0].binary,
        ...propsData,
      },
      stub: {
        GlDisclosureDropdown,
      },
    });
  }

  const findDefaultBlobActions = () => wrapper.findByTestId('default-actions-container');
  const findBlobDefaultActionsGroup = () => wrapper.findComponent(BlobDefaultActionsGroup);

  beforeEach(() => {
    createComponent();
  });

  describe('Default blob actions', () => {
    it('renders component', () => {
      expect(findDefaultBlobActions().exists()).toBe(true);
    });

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
});
