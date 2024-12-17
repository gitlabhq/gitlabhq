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
import RedactText from '~/projects/settings/repository/maintenance/redact_text.vue';
import WarningModal from '~/projects/settings/repository/maintenance/warning_modal.vue';
import replaceTextMutation from '~/projects/settings/repository/maintenance/graphql/mutations/replace_text.mutation.graphql';
import {
  TEST_HEADER_HEIGHT,
  TEST_PROJECT_PATH,
  TEST_TEXT,
  REPLACE_MUTATION_SUCCESS,
  REPLACE_MUTATION_FAIL,
} from './mock_data';

Vue.use(VueApollo);

jest.mock('~/lib/utils/dom_utils');
jest.mock('~/alert');

describe('Redact text', () => {
  let wrapper;
  let mutationMock;
  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  const createMockApolloProvider = (resolverMock) => {
    return createMockApollo([[replaceTextMutation, resolverMock]]);
  };

  const createComponent = (mutationResponse = REPLACE_MUTATION_SUCCESS) => {
    mutationMock = jest.fn().mockResolvedValue(mutationResponse);
    getContentWrapperHeight.mockReturnValue(TEST_HEADER_HEIGHT);
    wrapper = shallowMountExtended(RedactText, {
      apolloProvider: createMockApolloProvider(mutationMock),
      provide: {
        projectPath: TEST_PROJECT_PATH,
      },
    });
  };

  const findDrawerTrigger = () => wrapper.findByTestId('drawer-trigger');
  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findWarningModal = () => wrapper.findComponent(WarningModal);
  const redactTextButton = () => wrapper.findByTestId('redact-text');
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
        'Regex and glob patterns supported. Enter multiple entries on separate lines.',
      );
    });

    it('renders a modal, closed by default', () => {
      expect(findWarningModal().props()).toMatchObject({
        visible: false,
        title: 'You are about to permanently redact text from this project.',
        primaryText: 'Yes, redact matching strings',
        confirmPhrase: 'project/path',
        confirmLoading: false,
      });
    });
  });

  describe('redacting text', () => {
    beforeEach(() => findDrawerTrigger().vm.$emit('click'));

    it('opens the drawer', () => {
      expect(findDrawer().props('open')).toBe(true);
    });

    it('renders a text area without text', () => {
      expect(findTextarea().text()).toBe('');
    });

    it('disables the primary action by default', () => {
      expect(redactTextButton().props('disabled')).toBe(true);
    });

    describe('adding text', () => {
      beforeEach(() => findTextarea().vm.$emit('input', TEST_TEXT));

      it('enables the primary action when text is added', () => {
        expect(redactTextButton().props('disabled')).toBe(false);
      });

      describe('confirmation modal', () => {
        beforeEach(() => redactTextButton().vm.$emit('click'));

        it('renders the confirmation modal when redact text button is clicked', () => {
          expect(findWarningModal().props('visible')).toBe(true);
        });

        describe('removal confirmed (success)', () => {
          beforeEach(() => {
            findWarningModal().vm.$emit('confirm');
          });

          it('disables user input while loading', () => {
            expect(findTextarea().attributes().disabled).toBe('true');
            expect(redactTextButton().props('loading')).toBe(true);
          });

          it('calls the redact mutation', () => {
            expect(mutationMock).toHaveBeenCalledWith({
              replacements: [TEST_TEXT],
              projectPath: TEST_PROJECT_PATH,
            });
          });

          it('tracks click_redact_text_button_repository_settings', () => {
            const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
            expect(trackEventSpy).toHaveBeenCalledWith(
              'click_redact_text_button_repository_settings',
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
                'You will receive an email notification when the process is complete. To remove old versions from the repository, run housekeeping.',
              primaryButton: { clickHandler: expect.any(Function), text: 'Go to housekeeping' },
              title: 'Text redaction removal is scheduled.',
              variant: VARIANT_WARNING,
            });
          });
        });

        describe('removal confirmed (fail)', () => {
          beforeEach(async () => {
            createComponent(REPLACE_MUTATION_FAIL);

            // Simulates the workflow (open drawer → add text → click remove → confirm remove)
            findDrawerTrigger().vm.$emit('click');
            findTextarea().vm.$emit('input', TEST_TEXT);
            redactTextButton().vm.$emit('click');
            findWarningModal().vm.$emit('confirm');

            await waitForPromises();
          });

          it('generates an error alert upon failed mutation', () => {
            expect(createAlert).toHaveBeenCalledWith({
              message: 'Something went wrong while redacting text.',
              captureError: true,
            });
          });
        });
      });
    });
  });
});
