import { escape } from 'lodash';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __, n__, sprintf } from '~/locale';
import { InternalEvents } from '~/tracking';
import sensitiveDataPatterns from './secret_detection_patterns';

const CONTENT_TYPE = {
  COMMENT: 'comment',
  DESCRIPTION: 'description',
};

const defaultContentType = CONTENT_TYPE.COMMENT;

const documentationHref = helpPagePath('user/application_security/secret_detection/client/_index');

export const SHOW_CLIENT_SIDE_SECRET_DETECTION_WARNING =
  'show_client_side_secret_detection_warning';

const i18n = {
  title: (count) =>
    n__(
      'SecretDetection|Warning: Potential secret detected',
      'SecretDetection|Warning: Potential secrets detected',
      count,
    ),
  promptMessage: (count) =>
    n__(
      'SecretDetection|This %{contentType} appears to have the following secret in it. Are you sure you want to add this %{contentType}?',
      'SecretDetection|This %{contentType} appears to have the following secrets in it. Are you sure you want to add this %{contentType}?',
      count,
    ),
  primaryBtnText: __('Add %{contentType}'),
  secondaryBtnText: __('Edit %{contentType}'),
  helpString: __('Why am I seeing this warning?'),
};

const redactString = (inputString) => {
  if (inputString.length <= 9) return inputString;

  const prefix = inputString.substring(0, 5); // Keep the first 5 characters
  const suffix = inputString.substring(inputString.length - 4); // Keep the last 4 characters
  const redactLength = Math.min(inputString.length - prefix.length - suffix.length, 22);

  return `${prefix}${'*'.repeat(redactLength)}${suffix}`;
};

const formatMessage = (findings, contentType) => {
  const header = sprintf(i18n.promptMessage(findings.length), { contentType });

  const matchedPatterns = findings.map(({ patternName, matchedString }) => {
    const redactedString = redactString(matchedString);
    return `<li>${escape(patternName)}: ${escape(redactedString)}</li>`;
  });

  const message = `
    ${header}
    <p><ul>
      ${matchedPatterns.join('')}
    </ul>
    <a href="${documentationHref}" target="_blank" rel="noopener noreferrer">
      ${i18n.helpString}
    </a>
  `;

  return message;
};

const containsSensitiveToken = (message) => {
  if (!message || typeof message !== 'string') {
    return null;
  }
  const findings = [];

  for (const rule of sensitiveDataPatterns()) {
    const regex = new RegExp(rule.regex, 'gi');
    const matches = message.match(regex);

    if (matches) {
      matches.forEach((match) => {
        findings.push({
          patternName: rule.name,
          matchedString: match,
        });
      });
    }
  }

  return findings.length > 0 ? findings : false;
};

const confirmSensitiveAction = async (findings = [], contentType = defaultContentType) => {
  const title = i18n.title(findings.length);
  const modalHtmlMessage = formatMessage(findings, contentType);
  const primaryBtnText = sprintf(i18n.primaryBtnText, { contentType });
  const secondaryBtnText = sprintf(i18n.secondaryBtnText, { contentType });

  const confirmed = await confirmAction('', {
    title,
    modalHtmlMessage,
    primaryBtnVariant: 'danger',
    primaryBtnText,
    secondaryBtnText,
    hideCancel: true,
  });
  InternalEvents.trackEvent(SHOW_CLIENT_SIDE_SECRET_DETECTION_WARNING, {
    label: contentType,
    property: findings[0].patternName,
    value: confirmed ? 1 : 0,
  });
  return confirmed;
};

/**
 * Determines if the provided content contains sensitive patterns and confirms with the user when found.
 * @param {object} params - Parameters for detection and confirmation.
 * @param {string} params.content - The content to be checked for sensitive patterns.
 * @param {string} params.contentType - Type of content being checked.
 * @returns {Promise<boolean>} A Promise that resolves to:
 *   - true if no sensitive patterns are found.
 *   - true if sensitive patterns are found and the user chooses to proceed with them.
 *   - false if sensitive patterns are found and the user chooses to update the content.
 */
const detectAndConfirmSensitiveTokens = ({ content, contentType }) => {
  const sensitiveTokens = containsSensitiveToken(content);
  if (!sensitiveTokens) {
    return Promise.resolve(true);
  }
  return confirmSensitiveAction(sensitiveTokens, contentType);
};

export { detectAndConfirmSensitiveTokens, CONTENT_TYPE };
