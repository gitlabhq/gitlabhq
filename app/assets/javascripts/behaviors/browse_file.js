/*
  Used to setup all "Browse file" pickers and update the label when a file is chosen

  | Browse file...| No file chosen

  Sample configuration:

  %button.btn.js-browse-file-button{ data: { id: 'some-avatar' } }
    Browse file...
  %span.file_name.prepend-left-default.js-browse-file-name{ data: { id: 'some-avatar' } }
    No file chosen
  = f.file_field :file, accept: 'image/*', class: 'js-browse-file-input hidden',
                                           data: { id: 'some-avatar' }
*/
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
