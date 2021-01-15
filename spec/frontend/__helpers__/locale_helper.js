export const setLanguage = (languageCode) => {
  const htmlElement = document.querySelector('html');

  if (languageCode) {
    htmlElement.setAttribute('lang', languageCode);
  } else {
    htmlElement.removeAttribute('lang');
  }
};
