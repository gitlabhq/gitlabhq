import { nextTick } from 'vue';
import { GlDrawer, GlFormTextarea, GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import RemoveBlobs from '~/projects/settings/repository/maintenance/remove_blobs.vue';

jest.mock('~/lib/utils/dom_utils');

const TEST_HEADER_HEIGHT = '123px';

describe('Remove blobs', () => {
  let wrapper;

  const createComponent = () => {
    getContentWrapperHeight.mockReturnValue(TEST_HEADER_HEIGHT);
    wrapper = shallowMountExtended(RemoveBlobs);
  };

  const findDrawerTrigger = () => wrapper.findByTestId('drawer-trigger');
  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findModal = () => wrapper.findComponent(GlModal);
  const removeBlobsButton = () => wrapper.findByTestId('remove-blobs');
  const findTextarea = () => wrapper.findComponent(GlFormTextarea);

  beforeEach(() => createComponent());

  describe('initial state', () => {
    it('renders a button to open the drawer', () => {
      expect(findDrawerTrigger().exists()).toBe(true);
    });

    it('renders a drawer, closed by default', () => {
      expect(findDrawer().props()).toMatchObject({
        headerHeight: TEST_HEADER_HEIGHT,
        zIndex: DRAWER_Z_INDEX,
        open: false,
      });

      expect(findDrawer().text()).toContain(
        'Enter a list of object IDs to be removed to reduce repository size.',
      );
    });

    it('renders a modal, closed by default', () => {
      expect(findModal().props()).toMatchObject({
        visible: false,
        title: 'Remove blobs',
        modalId: 'remove-blobs-confirmation-modal',
        actionCancel: { text: 'Cancel' },
        actionPrimary: { text: 'Yes, remove blobs' },
      });

      expect(findModal().text()).toBe(
        'Removing blobs by ID cannot be undone. Are you sure you want to continue?',
      );
    });
  });

  describe('removing blobs', () => {
    beforeEach(() => findDrawerTrigger().vm.$emit('click'));

    it('opens the drawer', () => {
      expect(findDrawer().props('open')).toBe(true);
    });

    it('renders a text area without text', () => {
      expect(findTextarea().text('disabled')).toBe('');
    });

    it('disables the primary action by default', () => {
      expect(removeBlobsButton().props('disabled')).toBe(true);
    });

    describe('adding blob IDs', () => {
      beforeEach(() => findTextarea().vm.$emit('input', '1234'));

      it('enables the primary action when blob IDs are added', () => {
        expect(removeBlobsButton().props('disabled')).toBe(false);
      });

      describe('confirmation modal', () => {
        beforeEach(() => removeBlobsButton().vm.$emit('click'));

        it('renders the confirmation modal when remove blobs button is clicked', () => {
          expect(findModal().props('visible')).toBe(true);
        });

        it('closes the drawer when removal is confirmed', async () => {
          findModal().vm.$emit('primary');
          await nextTick();

          expect(findDrawer().props('open')).toBe(false);
        });
      });
    });
  });
});
