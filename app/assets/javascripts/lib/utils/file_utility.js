/**
 * Takes a file object and returns a data uri of its contents.
 *
 * @param {File} file
 * @returns {Promise<String>} rejects when the file cannot be read
 */
export function readFileAsDataURL(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.addEventListener('load', (e) => resolve(e.target.result), { once: true });
    // Without this the promise stays pending forever on an unreadable file, and
    // every caller waits on it indefinitely rather than failing.
    reader.addEventListener('error', () => reject(reader.error), { once: true });
    reader.readAsDataURL(file);
  });
}
