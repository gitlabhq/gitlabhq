import { GlModal, GlSprintf, GlFormInputGroup, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import MergeRequestByEmail from '~/merge_requests/list/components/merge_request_by_email.vue';
import SimpleCopyButton from '~/vue_shared/components/simple_copy_button.vue';

jest.mock('~/sentry/sentry_browser_wrapper');

const initialEmail = 'incoming+project-123-token-merge-request@example.com';
const resetPath = '/-/profile/reset_incoming_email_token';

const mockToastShow = jest.fn();

describe('MergeRequestByEmail', () => {
  let wrapper;
  let mockAxios;
  let glModalDirective;

  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  function createComponent(injectedProperties = {}) {
    glModalDirective = jest.fn();

    wrapper = extendedWrapper(
      shallowMount(MergeRequestByEmail, {
        stubs: {
          GlModal,
          GlSprintf,
          GlFormInputGroup,
          GlButton,
          SimpleCopyButton,
        },
        directives: {
          glModal: {
            bind(_, { value }) {
              glModalDirective(value);
            },
          },
        },
        mocks: {
          $toast: {
            show: mockToastShow,
          },
        },
        provide: {
          initialEmail,
          emailsHelpPagePath: '/help/development/emails.md#email-namespace',
          quickActionsHelpPath: '/help/user/project/quick_actions.md',
          markdownHelpPath: '/help/user/markdown.md',
          resetPath,
          ...injectedProperties,
        },
      }),
    );
  }

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockAxios.restore();
  });

  const findModalButton = () => wrapper.findByTestId('email-merge-request-link');
  const findFormInputGroup = () => wrapper.findComponent(GlFormInputGroup);
  const findMailtoButton = () =>
    wrapper
      .findAllComponents(GlButton)
      .wrappers.find(
        (btn) => btn.attributes('href') && btn.attributes('href').startsWith('mailto:'),
      );

  const clickResetEmail = async () => {
    await wrapper.findComponentByTestId('reset_email_token_link').trigger('click');

    await waitForPromises();
  };

  describe('modal button', () => {
    it('renders a link with "Email a new merge request to this project"', () => {
      createComponent();
      expect(findModalButton().text()).toBe('Email a new merge request to this project');
    });

    it('binds the modal directive to open the correct modal', () => {
      createComponent();

      expect(glModalDirective).toHaveBeenCalledWith('merge-request-email-modal');
    });

    it('has the internal event tracking attribute', () => {
      createComponent();

      expect(findModalButton().attributes('data-event-tracking')).toBe(
        'click_email_merge_request_project_merge_requests_list_page',
      );
    });

    it('tracks the internal event when clicked', () => {
      createComponent();

      const { triggerEvent, trackEventSpy } = bindInternalEventDocument(wrapper.element);
      triggerEvent(findModalButton().element);

      expect(trackEventSpy).toHaveBeenCalledWith(
        'click_email_merge_request_project_merge_requests_list_page',
        {},
      );
    });
  });

  describe('modal', () => {
    it('renders a read-only email input field', () => {
      createComponent();

      expect(findFormInputGroup().props('value')).toBe(initialEmail);
    });

    it('renders a mailto button with url-encoded subject and body', () => {
      createComponent();

      expect(findMailtoButton().attributes('href')).toBe(
        `mailto:${initialEmail}?subject=${encodeURIComponent('Enter the merge request title')}&body=${encodeURIComponent('Enter the merge request description')}`,
      );
    });

    describe('reset email', () => {
      it('should send request to reset email token', async () => {
        mockAxios.onPut(resetPath).reply(200, { new_address: initialEmail });

        createComponent();

        await clickResetEmail();

        expect(mockAxios.history.put).toHaveLength(1);
        expect(mockAxios.history.put[0].url).toBe(resetPath);
      });

      it('should update the email when the request succeeds', async () => {
        const newEmail = 'incoming+project-123-newtoken-merge-request@example.com';
        mockAxios.onPut(resetPath).reply(200, { new_address: newEmail });

        createComponent();
        await clickResetEmail();

        expect(findFormInputGroup().props('value')).toBe(newEmail);
      });

      it('should show a toast message and report to Sentry when the request fails', async () => {
        mockAxios.onPut(resetPath).reply(500);

        createComponent();

        await clickResetEmail();

        expect(mockToastShow).toHaveBeenCalledWith(
          'There was an error when resetting email token.',
        );
        expect(Sentry.captureException).toHaveBeenCalled();
        expect(findFormInputGroup().props('value')).toBe(initialEmail);
      });

      it('does not send a request when resetPath is not provided', async () => {
        createComponent({ resetPath: '' });

        await clickResetEmail();

        expect(mockAxios.history.put).toHaveLength(0);
      });

      it('does not send a second request while a reset is already in progress', async () => {
        mockAxios.onPut(resetPath).reply(200, { new_address: initialEmail });

        createComponent();

        const resetLink = wrapper.findComponentByTestId('reset_email_token_link');
        await resetLink.trigger('click');
        await resetLink.trigger('click');
        await waitForPromises();

        expect(mockAxios.history.put).toHaveLength(1);
      });
    });
  });
});
