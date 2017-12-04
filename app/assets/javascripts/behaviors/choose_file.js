/*
  Used to setup all "Choose file" pickers and update the label when a file is chosen

  | Choose file...| No file chosen

  Sample configuration:

  %button.btn.js-choose-file-button{ data: { id: 'some-avatar' } }
    Choose file...
  %span.file_name.prepend-left-default.js-choose-file-name{ data: { id: 'some-avatar' } }
    No file chosen
  = f.file_field :file, accept: 'image/*', class: 'js-choose-file-input hidden',
                                           data: { id: 'some-avatar' }
*/
export default function setupChooseFile() {
  const chooseButtons = document.querySelectorAll('.js-choose-file-button');
  chooseButtons.forEach((chooseButton) => {
    const id = chooseButton.dataset.id;

    const fileInput = document.querySelector(`.js-choose-file-input[data-id="${id}"]`);
    const fileNameLabel = document.querySelector(`.js-choose-file-name[data-id="${id}"]`);

    chooseButton.addEventListener('click', () => {
      fileInput.click();
    });

    fileInput.addEventListener('change', () => {
      const filename = fileInput.value.replace(/^.*[\\/]/, '');
      fileNameLabel.textContent = filename;
    });
  });
}
