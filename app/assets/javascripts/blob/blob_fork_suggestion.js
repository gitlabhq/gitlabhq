function BlobForkSuggestion(openButton, cancelButton, suggestionSection) {
  if (openButton) {
    openButton.addEventListener('click', () => {
      suggestionSection.classList.remove('hidden');
    });
  }

  if (cancelButton) {
    cancelButton.addEventListener('click', () => {
      suggestionSection.classList.add('hidden');
    });
  }
}

export default BlobForkSuggestion;
