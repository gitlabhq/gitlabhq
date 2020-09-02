import { __ } from '~/locale';

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

  const serviceDeskSupportedTitle = __(
    'Use Service Desk to connect with your users (e.g. to offer customer support) through email right inside GitLab',
  );

  const serviceDeskSupportedMessage = __(
    'Those emails automatically become issues (with the comments becoming the email conversation) listed here.',
  );

  const commonDescription = `
  <span>${serviceDeskSupportedMessage}</span>
  <a href="${serviceDeskHelpPage}">${__('Read more')}</a>`;

  return {
    serviceDeskEnabledAndCanEditProjectSettings: {
      title: serviceDeskSupportedTitle,
      svgPath,
      description: `<p>${__('Have your users email')}
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
      primaryText: __('Turn on Service Desk'),
    },
    serviceDeskDisabledAndCannotEditProjectSettings: {
      title: serviceDeskSupportedTitle,
      svgPath,
      description: commonDescription,
    },
    serviceDeskIsNotSupported: {
      title: __('Service Desk is not supported'),
      svgPath,
      description: __(
        'In order to enable Service Desk for your instance, you must first set up incoming email.',
      ),
      primaryLink: incomingEmailHelpPage,
      primaryText: __('More information'),
    },
    serviceDeskIsNotEnabled: {
      title: __('Service Desk is not enabled'),
      svgPath,
      description: __(
        'For help setting up the Service Desk for your instance, please contact an administrator.',
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
