export default function setupBrowseFile() {
  const browseButtons = document.querySelectorAll('.js-browse-file-button');
  browseButtons.forEach((browseButton) => {
    const id = browseButton.dataset.id;

    const fileInput = document.querySelector(`.js-browse-file-input[data-id="${id}"]`);
    const fileNameLabel = document.querySelector(`.js-browse-file-name[data-id="${id}"]`);

    browseButton.addEventListener('click', () => {
      fileInput.click();
    });

    fileInput.addEventListener('change', () => {
      const filename = fileInput.value.replace(/^.*[\\/]/, '');
      fileNameLabel.textContent = filename;
    });
  });
}
