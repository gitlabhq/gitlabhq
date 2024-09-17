import { confirmAction } from './confirm_action';

function confirmViaGlModal(message, element) {
  const {
    confirmBtnVariant,
    title,
    isHtmlMessage,
    trackingEventName,
    trackingEventLabel,
    trackingEventProperty,
    trackingEventValue,
  } = element.dataset;

  const screenReaderText =
    element.querySelector('.gl-sr-only')?.textContent ||
    element.querySelector('.sr-only')?.textContent ||
    element.getAttribute('aria-label');

  const getTrackingEventConfig = (trackingEventNameFromDataset) => {
    if (!trackingEventNameFromDataset) return null;

    return {
      name: trackingEventNameFromDataset,
      label: trackingEventLabel,
      property: trackingEventProperty,
      value: trackingEventValue,
    };
  };

  const trackingEventConfig = getTrackingEventConfig(trackingEventName);

  const config = {
    ...(screenReaderText && { primaryBtnText: screenReaderText }),
    ...(confirmBtnVariant && { primaryBtnVariant: confirmBtnVariant }),
    ...(title && { title }),
    ...(isHtmlMessage && { modalHtmlMessage: message }),
  };

  if (trackingEventConfig) {
    config.trackingEvent = trackingEventConfig;
  }

  return confirmAction(message, config);
}

export { confirmAction, confirmViaGlModal };
