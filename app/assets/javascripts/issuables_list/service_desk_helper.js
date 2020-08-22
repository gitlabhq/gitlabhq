import { __ } from '~/locale';

/**
 * Returns the attributes used for gl-empty-state in the Service Desk issues list.
 */
export function emptyStateHelper(emptyStateMeta) {
  const { isServiceDeskSupported, svgPath, serviceDeskHelpPage } = emptyStateMeta;

  if (isServiceDeskSupported) {
    const title = __(
      'Use Service Desk to connect with your users (e.g. to offer customer support) through email right inside GitLab',
    );
    const commonMessage = __(
      'Those emails automatically become issues (with the comments becoming the email conversation) listed here.',
    );
    const commonDescription = `
      <span>${commonMessage}</span>
      <a href="${serviceDeskHelpPage}">${__('Read more')}</a>`;

    if (emptyStateMeta.canEditProjectSettings && emptyStateMeta.isServiceDeskEnabled) {
      return {
        title,
        svgPath,
        description: `<p>${__('Have your users email')} <code>${
          emptyStateMeta.serviceDeskAddress
        }</code></p> ${commonDescription}`,
      };
    }

    if (emptyStateMeta.canEditProjectSettings && !emptyStateMeta.isServiceDeskEnabled) {
      return {
        title,
        svgPath,
        description: commonDescription,
        primaryLink: emptyStateMeta.editProjectPage,
        primaryText: __('Turn on Service Desk'),
      };
    }

    return {
      title,
      svgPath,
      description: commonDescription,
    };
  }

  return {
    title: __('Service Desk is enabled but not yet active'),
    svgPath,
    description: __('You must set up incoming email before it becomes active.'),
    primaryLink: emptyStateMeta.incomingEmailHelpPage,
    primaryText: __('More information'),
  };
}
