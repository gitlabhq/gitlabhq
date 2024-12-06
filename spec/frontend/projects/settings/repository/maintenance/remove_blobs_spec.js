import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlDrawer, GlFormTextarea } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { createAlert, VARIANT_WARNING } from '~/alert';
import RemoveBlobs from '~/projects/settings/repository/maintenance/remove_blobs.vue';
import WarningModal from '~/projects/settings/repository/maintenance/warning_modal.vue';
import removeBlobsMutation from '~/projects/settings/repository/maintenance/graphql/mutations/remove_blobs.mutation.graphql';
import {
  TEST_HEADER_HEIGHT,
  TEST_PROJECT_PATH,
  TEST_BLOB_ID,
  REMOVE_MUTATION_SUCCESS,
  REMOVE_MUTATION_FAIL,
} from './mock_data';

Vue.use(VueApollo);

jest.mock('~/lib/utils/dom_utils');
jest.mock('~/alert');

describe('Remove blobs', () => {
  let wrapper;
  let mutationMock;
  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  const createMockApolloProvider = (resolverMock) => {
    return createMockApollo([[removeBlobsMutation, resolverMock]]);
  };

  const createComponent = (mutationResponse = REMOVE_MUTATION_SUCCESS) => {
    mutationMock = jest.fn().mockResolvedValue(mutationResponse);
    getContentWrapperHeight.mockReturnValue(TEST_HEADER_HEIGHT);
    wrapper = shallowMountExtended(RemoveBlobs, {
      apolloProvider: createMockApolloProvider(mutationMock),
      provide: {
        projectPath: TEST_PROJECT_PATH,
      },
    });
  };

  const findDrawerTrigger = () => wrapper.findByTestId('drawer-trigger');
  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findWarningModal = () => wrapper.findComponent(WarningModal);
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
      expect(findWarningModal().props()).toMatchObject({
        visible: false,
        title: 'You are about to permanently remove blobs from this project.',
        primaryText: 'Yes, remove blobs',
        confirmPhrase: 'project/path',
        confirmLoading: false,
      });
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
      beforeEach(() => findTextarea().vm.$emit('input', TEST_BLOB_ID));

      it('enables the primary action when valid blob IDs are added', () => {
        expect(removeBlobsButton().props('disabled')).toBe(false);
      });

      it('disables the primary action when invalid blob IDs are added', async () => {
        findTextarea().vm.$emit('input', 'invalid');
        await nextTick();

        expect(removeBlobsButton().props('disabled')).toBe(true);
      });

      describe('confirmation modal', () => {
        beforeEach(() => removeBlobsButton().vm.$emit('click'));

        it('renders the confirmation modal when remove blobs button is clicked', () => {
          expect(findWarningModal().props('visible')).toBe(true);
        });

        describe('removal confirmed (success)', () => {
          beforeEach(() => {
            findWarningModal().vm.$emit('confirm');
          });

          it('disables user input while loading', () => {
            expect(findTextarea().attributes().disabled).toBe('true');
            expect(removeBlobsButton().props('loading')).toBe(true);
          });

          it('calls the remove mutation', () => {
            expect(mutationMock).toHaveBeenCalledWith({
              blobOids: [TEST_BLOB_ID],
              projectPath: TEST_PROJECT_PATH,
            });
          });

          it('tracks click_remove_blob_button_repository_settings', () => {
            const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
            expect(trackEventSpy).toHaveBeenCalledWith(
              'click_remove_blob_button_repository_settings',
              {},
              undefined,
            );
          });

          it('closes the drawer when removal is confirmed', async () => {
            await waitForPromises();

            expect(findDrawer().props('open')).toBe(false);
          });

          it('clears the input on the modal when the hide event is emitted', async () => {
            findWarningModal().vm.$emit('hide');
            await nextTick();

            expect(findWarningModal().props('visible')).toBe(false);
          });

          it('generates a housekeeping alert', async () => {
            await waitForPromises();

            expect(createAlert).toHaveBeenCalledWith({
              message:
                'You will receive an email notification when the process is complete. Run housekeeping to remove old versions from repository.',
              primaryButton: { clickHandler: expect.any(Function), text: 'Go to housekeeping' },
              title: 'Blobs removal is scheduled.',
              variant: VARIANT_WARNING,
            });
          });
        });

        describe('removal confirmed (fail)', () => {
          beforeEach(async () => {
            createComponent(REMOVE_MUTATION_FAIL);

            // Simulates the workflow (open drawer → add blobId → click remove → confirm remove)
            findDrawerTrigger().vm.$emit('click');
            findTextarea().vm.$emit('input', TEST_BLOB_ID);
            removeBlobsButton().vm.$emit('click');
            findWarningModal().vm.$emit('confirm');

            await waitForPromises();
          });

          it('generates an error alert upon failed mutation', () => {
            expect(createAlert).toHaveBeenCalledWith({
              message: 'Something went wrong while removing blobs.',
              captureError: true,
            });
          });
        });
      });
    });
  });
});
