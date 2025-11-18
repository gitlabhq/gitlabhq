/**
 * Programmatically copies a text string to the clipboard. Attempts to copy in both secure and non-secure contexts.
 *
 * Accepts a container element. This helps ensure the text can get copied to the clipboard correctly in non-secure
 * environments, the container should be active (such as a button in a modal) to ensure the content can be copied.
 *
 * @param {String} text - Text to copy
 * @param {HTMLElement} container - Container to dummy textarea (for fallback behavior).
 */
export const copyToClipboard = (text, container = document.body) => {
  // First, try a simple clipboard.writeText (works on https and localhost)

  // eslint-disable-next-line no-restricted-properties -- navigator.clipboard intentionally used here
  if (navigator.clipboard && window.isSecureContext) {
    // eslint-disable-next-line no-restricted-properties -- navigator.clipboard intentionally used here
    return navigator.clipboard.writeText(text);
  }

  // Second, try execCommand to copy from a dynamically created invisible textarea (for http and older browsers)
  const textarea = document.createElement('textarea');
  textarea.value = text;
  textarea.style.position = 'absolute';
  textarea.style.left = '-9999px'; // eslint-disable-line @gitlab/require-i18n-strings
  textarea.style.top = '0';
  textarea.setAttribute('readonly', ''); // prevent keyboard popup on mobile

  // textarea must be in document to be selectable, but we add it to the button so it works in modals
  container.appendChild(textarea);

  textarea.select(); // for Safari
  textarea.setSelectionRange(0, textarea.value.length); // for mobile devices

  try {
    const done = document.execCommand('copy');
    container.removeChild(textarea);
    // eslint-disable-next-line @gitlab/require-i18n-strings
    return done ? Promise.resolve() : Promise.reject(new Error('Copy command failed'));
  } catch (err) {
    container.removeChild(textarea);
    return Promise.reject(err);
  }
};
