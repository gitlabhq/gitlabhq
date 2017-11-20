function updateAutoDevopsRadios(radioWrappers) {
  radioWrappers.forEach((radioWrapper) => {
    const radio = radioWrapper.querySelector('.js-auto-devops-enable-radio');
    const runPipelineCheckboxWrapper = radioWrapper.querySelector('.js-run-auto-devops-pipeline-checkbox-wrapper');
    const runPipelineCheckbox = radioWrapper.querySelector('.js-run-auto-devops-pipeline-checkbox');

    if (runPipelineCheckbox) {
      runPipelineCheckbox.checked = radio.checked;
      runPipelineCheckboxWrapper.classList.toggle('hide', !radio.checked);
    }
  });
}

export default function initCiCdSettings() {
  const radioWrappers = document.querySelectorAll('.js-auto-devops-enable-radio-wrapper');
  radioWrappers.forEach(radioWrapper =>
    radioWrapper.addEventListener('change', () => updateAutoDevopsRadios(radioWrappers)),
  );
}
