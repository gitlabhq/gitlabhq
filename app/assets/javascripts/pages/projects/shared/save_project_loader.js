export default function initProjectLoadingSpinner() {
  const formContainer = document.querySelector('.project-edit-container');
  if (formContainer == null) {
    return;
  }

  const loadingSpinner = document.querySelector('.save-project-loader');

  // show loading spinner when saving
  formContainer.addEventListener('ajax:before', () => {
    formContainer.style.display = 'none';
    loadingSpinner.style.display = 'block';
  });
}
