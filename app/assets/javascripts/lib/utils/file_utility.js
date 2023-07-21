/**
 * Takes a file object and returns a data uri of its contents.
 *
 * @param {File} file
 */
export function readFileAsDataURL(file) {
  return new Promise((resolve) => {
    const reader = new FileReader();
    reader.addEventListener('load', (e) => resolve(e.target.result), { once: true });
    reader.readAsDataURL(file);
  });
}
