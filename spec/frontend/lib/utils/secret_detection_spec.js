import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { InternalEvents } from '~/tracking';
import {
  sensitiveMessages,
  nonSensitiveMessages,
  secretDetectionFindings,
  sensitiveMessagesWithInstancePrefix,
} from './mock_data';

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

    describe('when instance token prefix is set', () => {
      describe.each(sensitiveMessagesWithInstancePrefix)(
        'for message with instance prefix: %s',
        (message) => {
          beforeEach(() => {
            gon.instance_token_prefix = 'instanceprefix';
          });

          afterEach(() => {
            delete gon.instance_token_prefix;
          });

          it('should show warning', async () => {
            await detectAndConfirmSensitiveTokens({ content: message });
            expect(confirmAction).toHaveBeenCalled();
          });

          it('should contain token including instance prefix', async () => {
            await detectAndConfirmSensitiveTokens({ content: message });

            const confirmActionArgs = confirmAction.mock.calls[0][1];
            expect(confirmActionArgs.modalHtmlMessage).toContain(`instanceprefix-`);
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
        },
      );
    });
  });

  describe('when custom pat prefix is set', () => {
    beforeEach(() => {
      gon.pat_prefix = 'specpat-';
    });

    afterEach(() => {
      delete gon.pat_prefix;
    });

    const validPatPrefixTokenMessage = 'token: specpat-cgyKc1k_AsnEpmP-5fRL';
    const validDefaultPrefixTokenMessage = 'token: glpat-cgyKc1k_AsnEpmP-5fRL';
    const invalidTokenMessage = 'token: invalid-token';

    it('should detect the valid token with a custom pat prefix', async () => {
      await detectAndConfirmSensitiveTokens({ content: validPatPrefixTokenMessage });
      expect(confirmAction).toHaveBeenCalled();
    });

    it('should detect the valid token with the bare glpat- prefix', async () => {
      await detectAndConfirmSensitiveTokens({ content: validDefaultPrefixTokenMessage });
      expect(confirmAction).toHaveBeenCalled();
    });

    it('should not detect the invalid token', async () => {
      await detectAndConfirmSensitiveTokens({ content: invalidTokenMessage });
      expect(confirmAction).not.toHaveBeenCalled();
    });

    describe('when custom pat prefix contains character that needs escaping', () => {
      beforeEach(() => {
        gon.pat_prefix = 'specpat*-';
      });

      const validTokenMessageWithSpecialCharacter = 'token: specpat*-cgyKc1k_AsnEpmP-5fRL';

      it('should escape the regex and detect the valid token', async () => {
        await detectAndConfirmSensitiveTokens({ content: validTokenMessageWithSpecialCharacter });
        expect(confirmAction).toHaveBeenCalled();
      });
    });
  });

  describe('when both instance token prefix and custom pat prefix are set', () => {
    beforeEach(() => {
      gon.instance_token_prefix = 'instanceprefix';
      gon.pat_prefix = 'custompat-';
    });

    afterEach(() => {
      delete gon.instance_token_prefix;
      delete gon.pat_prefix;
    });

    const getModalHtmlMessage = () => confirmAction.mock.calls[0][1].modalHtmlMessage;

    it('should detect token with instance prefix and hardcoded glpat-', async () => {
      await detectAndConfirmSensitiveTokens({
        content: 'token: instanceprefix-glpat-cgyKc1k_AsnEpmP-5fRL',
      });

      expect(getModalHtmlMessage()).toContain('instanceprefix-glpat-cgyKc1k_AsnEpmP-5fRL');
    });

    it('should detect token with custom pat prefix', async () => {
      await detectAndConfirmSensitiveTokens({
        content: 'token: custompat-cgyKc1k_AsnEpmP-5fRL',
      });

      expect(getModalHtmlMessage()).toContain('custompat-cgyKc1k_AsnEpmP-5fRL');
    });

    it('should detect token with bare glpat- prefix', async () => {
      await detectAndConfirmSensitiveTokens({
        content: 'token: glpat-cgyKc1k_AsnEpmP-5fRL',
      });
      expect(getModalHtmlMessage()).toContain('glpat-cgyKc1k_AsnEpmP-5fRL');
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

    describe('with single finding', () => {
      const [{ message, type, secret }] = findings;
      it('should call confirmAction with correct parameters', async () => {
        await detectAndConfirmSensitiveTokens({ content: message });

        const confirmActionArgs = confirmAction.mock.calls[0][1];
        expect(confirmActionArgs).toMatchObject(baseConfirmActionParams);
        expect(confirmActionArgs.title).toBe('Warning: Potential secret detected');
        expect(confirmActionArgs.modalHtmlMessage).toContain(`${type}: ${secret}`);
      });
    });

    describe('with multiple findings', () => {
      const combinedMessage = findings.map(({ message }) => message).join(' ');

      it('should call confirmAction with correct parameters', async () => {
        await detectAndConfirmSensitiveTokens({ content: combinedMessage });

        const confirmActionArgs = confirmAction.mock.calls[0][1];
        expect(confirmActionArgs).toMatchObject(baseConfirmActionParams);
        expect(confirmActionArgs.title).toBe('Warning: Potential secrets detected');

        findings.forEach(({ type, secret }) => {
          expect(confirmActionArgs.modalHtmlMessage).toContain(`${type}: ${secret}`);
        });
      });
    });

    describe('with repeated finding', () => {
      const { message, type, secret } = findings.at(-1);
      it('should call confirmAction with correct parameters', async () => {
        await detectAndConfirmSensitiveTokens({ content: message });

        const confirmActionArgs = confirmAction.mock.calls[0][1];
        const stringToMatch = `${type}: ${secret}`;
        expect(confirmActionArgs).toMatchObject(baseConfirmActionParams);
        expect(confirmActionArgs.title).toBe('Warning: Potential secret detected');
        const tokenRegex = new RegExp(stringToMatch, 'g');
        const matches = confirmActionArgs.modalHtmlMessage.match(tokenRegex);

        expect(matches).toHaveLength(1);
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
