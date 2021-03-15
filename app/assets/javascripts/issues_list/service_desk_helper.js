import { s__ } from '~/locale';

/**
 * Generates empty state messages for Service Desk issues list.
 *
 * @param {emptyStateMeta} emptyStateMeta - Meta data used to generate empty state messages
 * @returns {Object} Object containing empty state messages generated using the meta data.
 */
export function generateMessages(emptyStateMeta) {
  const {
    svgPath,
    serviceDeskHelpPage,
    serviceDeskAddress,
    editProjectPage,
    incomingEmailHelpPage,
  } = emptyStateMeta;

  const serviceDeskSupportedTitle = s__(
    'ServiceDesk|Use Service Desk to connect with your users and offer customer support through email right inside GitLab',
  );

  const serviceDeskSupportedMessage = s__(
    'ServiceDesk|Issues created from Service Desk emails appear here. Each comment becomes part of the email conversation.',
  );

  const commonDescription = `
  <span>${serviceDeskSupportedMessage}</span>
  <a href="${serviceDeskHelpPage}">${s__('Learn more.')}</a>`;

  return {
    serviceDeskEnabledAndCanEditProjectSettings: {
      title: serviceDeskSupportedTitle,
      svgPath,
      description: `<p>${s__('ServiceDesk|Your users can send emails to this address:')}
      <code>${serviceDeskAddress}</code>
      </p>
      ${commonDescription}`,
    },
    serviceDeskEnabledAndCannotEditProjectSettings: {
      title: serviceDeskSupportedTitle,
      svgPath,
      description: commonDescription,
    },
    serviceDeskDisabledAndCanEditProjectSettings: {
      title: serviceDeskSupportedTitle,
      svgPath,
      description: commonDescription,
      primaryLink: editProjectPage,
      primaryText: s__('ServiceDesk|Enable Service Desk'),
    },
    serviceDeskDisabledAndCannotEditProjectSettings: {
      title: serviceDeskSupportedTitle,
      svgPath,
      description: commonDescription,
    },
    serviceDeskIsNotSupported: {
      title: s__('ServiceDesk|Service Desk is not supported'),
      svgPath,
      description: s__(
        'ServiceDesk|To enable Service Desk on this instance, an instance administrator must first set up incoming email.',
      ),
      primaryLink: incomingEmailHelpPage,
      primaryText: s__('Learn more.'),
    },
    serviceDeskIsNotEnabled: {
      title: s__('ServiceDesk|Service Desk is not enabled'),
      svgPath,
      description: s__(
        'ServiceDesk|For help setting up the Service Desk for your instance, please contact an administrator.',
      ),
    },
  };
}

/**
 * Returns the attributes used for gl-empty-state in the Service Desk issues list.
 *
 * @param {Object} emptyStateMeta - Meta data used to generate empty state messages
 * @returns {Object}
 */
export function emptyStateHelper(emptyStateMeta) {
  const messages = generateMessages(emptyStateMeta);

  const { isServiceDeskSupported, canEditProjectSettings, isServiceDeskEnabled } = emptyStateMeta;

  if (isServiceDeskSupported) {
    if (isServiceDeskEnabled && canEditProjectSettings) {
      return messages.serviceDeskEnabledAndCanEditProjectSettings;
    }

    if (isServiceDeskEnabled && !canEditProjectSettings) {
      return messages.serviceDeskEnabledAndCannotEditProjectSettings;
    }

    // !isServiceDeskEnabled && canEditProjectSettings
    if (canEditProjectSettings) {
      return messages.serviceDeskDisabledAndCanEditProjectSettings;
    }

    // !isServiceDeskEnabled && !canEditProjectSettings
    return messages.serviceDeskDisabledAndCannotEditProjectSettings;
  }

  // !serviceDeskSupported && canEditProjectSettings
  if (canEditProjectSettings) {
    return messages.serviceDeskIsNotSupported;
  }

  // !serviceDeskSupported && !canEditProjectSettings
  return messages.serviceDeskIsNotEnabled;
}
