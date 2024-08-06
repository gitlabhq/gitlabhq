import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { InternalEvents } from '~/tracking';
import { sensitiveMessages, nonSensitiveMessages, secretDetectionFindings } from './mock_data';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');

const mockConfirmAction = ({ confirmed }) => {
  confirmAction.mockResolvedValueOnce(confirmed);
};

const trackingEventName = 'show_client_side_secret_detection_warning';
const trackingEventPayload = {
  label: 'comment',
  property: 'GitLab personal access token',
  value: 0,
};

describe('detectAndConfirmSensitiveTokens', () => {
  beforeEach(() => {
    jest.spyOn(InternalEvents, 'trackEvent');
  });
  afterEach(() => {
    jest.resetAllMocks();
  });

  describe('content without sensitive tokens', () => {
    it.each(nonSensitiveMessages)(
      'returns true and does not show warning for message: %s',
      async (message) => {
        const result = await detectAndConfirmSensitiveTokens({ content: message });
        expect(result).toBe(true);
        expect(confirmAction).not.toHaveBeenCalled();
      },
    );
    it('does not trigger event tracking', () => {
      const message = 'This is a test message';
      detectAndConfirmSensitiveTokens({ content: message });
      expect(InternalEvents.trackEvent).not.toHaveBeenCalled();
    });
  });

  describe('content with sensitive tokens', () => {
    describe.each(sensitiveMessages)('for message: %s', (message) => {
      it('should show warning', async () => {
        await detectAndConfirmSensitiveTokens({ content: message });
        expect(confirmAction).toHaveBeenCalled();
      });

      it('should return true when confirmed is true', async () => {
        mockConfirmAction({ confirmed: true });

        const result = await detectAndConfirmSensitiveTokens({ content: message });
        expect(result).toBe(true);
      });

      it('should return false when confirmed is false', async () => {
        mockConfirmAction({ confirmed: false });

        const result = await detectAndConfirmSensitiveTokens({ content: message });
        expect(result).toBe(false);
      });
    });

    describe('event tracking', () => {
      const [message] = sensitiveMessages;

      it('should track correct event when warning is dismissed', async () => {
        mockConfirmAction({ confirmed: false });

        await detectAndConfirmSensitiveTokens({ content: message });
        expect(InternalEvents.trackEvent).toHaveBeenCalledWith(trackingEventName, {
          ...trackingEventPayload,
          value: 0,
        });
      });
      it('should track correct event when warning is accepted', async () => {
        mockConfirmAction({ confirmed: true });

        await detectAndConfirmSensitiveTokens({ content: message });
        expect(InternalEvents.trackEvent).toHaveBeenCalledWith(trackingEventName, {
          ...trackingEventPayload,
          value: 1,
        });
      });
    });
  });

  describe('when custom pat prefix is set', () => {
    beforeEach(() => {
      gon.pat_prefix = 'specpat-';
    });

    const validTokenMessage = 'token: specpat-mGYFaXBmNLvLmrEb7xdf';
    const invalidTokenMessage = 'token: glpat-mGYFaXBmNLvLmrEb7xdf';

    it('should detect the valid token', async () => {
      await detectAndConfirmSensitiveTokens({ content: validTokenMessage });
      expect(confirmAction).toHaveBeenCalled();
    });

    it('should not detect the invalid token', async () => {
      await detectAndConfirmSensitiveTokens({ content: invalidTokenMessage });
      expect(confirmAction).not.toHaveBeenCalled();
    });
  });

  describe('warning modal', () => {
    const findings = secretDetectionFindings;
    const baseConfirmActionParams = {
      primaryBtnVariant: 'danger',
      primaryBtnText: 'Add comment',
      secondaryBtnText: 'Edit comment',
      hideCancel: true,
      modalHtmlMessage: expect.any(String),
    };

    describe('with single findings', () => {
      const [{ message, type, redactedString }] = findings;
      it('should call confirmAction with correct parameters', async () => {
        await detectAndConfirmSensitiveTokens({ content: message });

        const confirmActionArgs = confirmAction.mock.calls[0][1];
        expect(confirmActionArgs).toMatchObject(baseConfirmActionParams);
        expect(confirmActionArgs.title).toBe('Warning: Potential secret detected');
        expect(confirmActionArgs.modalHtmlMessage).toContain(`${type}: ${redactedString}`);
      });
    });

    describe('with multiple findings', () => {
      const combinedMessage = findings.map(({ message }) => message).join(' ');

      it('should call confirmAction with correct parameters', async () => {
        await detectAndConfirmSensitiveTokens({ content: combinedMessage });

        const confirmActionArgs = confirmAction.mock.calls[0][1];
        expect(confirmActionArgs).toMatchObject(baseConfirmActionParams);
        expect(confirmActionArgs.title).toBe('Warning: Potential secrets detected');

        findings.forEach(({ type, redactedString }) => {
          expect(confirmActionArgs.modalHtmlMessage).toContain(`${type}: ${redactedString}`);
        });
      });
    });

    describe('with different content type', () => {
      const testCases = [
        [
          'comment',
          'This comment appears to have the following secret in it. Are you sure you want to add this comment?',
        ],
        [
          'description',
          'This description appears to have the following secret in it. Are you sure you want to add this description?',
        ],
      ];

      it.each(testCases)('content type: %s', async (contentType, expectedMessage) => {
        const [{ message }] = findings;
        await detectAndConfirmSensitiveTokens({ content: message, contentType });

        const confirmActionArgs = confirmAction.mock.calls[0][1];
        expect(confirmActionArgs.modalHtmlMessage).toContain(expectedMessage);
        expect(InternalEvents.trackEvent).toHaveBeenCalledWith(trackingEventName, {
          ...trackingEventPayload,
          label: contentType,
        });
      });
    });
  });
});
