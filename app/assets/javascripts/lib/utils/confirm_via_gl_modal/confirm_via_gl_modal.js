import { confirmAction } from './confirm_action';

function confirmViaGlModal(message, element) {
  const { confirmBtnVariant, title, isHtmlMessage } = element.dataset;

  const screenReaderText =
    element.querySelector('.gl-sr-only')?.textContent ||
    element.querySelector('.sr-only')?.textContent ||
    element.getAttribute('aria-label');

  const config = {
    ...(screenReaderText && { primaryBtnText: screenReaderText }),
    ...(confirmBtnVariant && { primaryBtnVariant: confirmBtnVariant }),
    ...(title && { title }),
    ...(isHtmlMessage && { modalHtmlMessage: message }),
  };

  return confirmAction(message, config);
}

export { confirmAction, confirmViaGlModal };
