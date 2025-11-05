/**
 * Encodes HTML special characters in a string to their corresponding HTML entities.
 * This function helps prevent XSS attacks by escaping potentially dangerous characters
 * that could be interpreted as HTML markup.
 *
 * The following characters are encoded:
 * - & → &amp;
 * - < → &lt;
 * - > → &gt;
 * - ' → &apos;
 * - " → &quot;
 *
 * @param {string} [str=''] - The string to encode. Defaults to empty string if not provided.
 * @returns {string} The HTML-encoded string with special characters converted to entities.
 */
export function htmlEncode(str = '') {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/'/g, '&apos;')
    .replace(/"/g, '&quot;');
}
