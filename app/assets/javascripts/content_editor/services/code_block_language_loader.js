export default class CodeBlockLanguageLoader {
  constructor(lowlight) {
    this.lowlight = lowlight;
  }

  isLanguageLoaded(language) {
    return this.lowlight.registered(language);
  }

  loadLanguagesFromDOM(domTree) {
    const languages = [];

    domTree.querySelectorAll('pre').forEach((preElement) => {
      languages.push(preElement.getAttribute('lang'));
    });

    return this.loadLanguages(languages);
  }

  loadLanguages(languageList = []) {
    const loaders = languageList
      .filter((languageName) => !this.isLanguageLoaded(languageName))
      .map((languageName) => {
        return import(
          /* webpackChunkName: 'highlight.language.js' */ `highlight.js/lib/languages/${languageName}`
        )
          .then(({ default: language }) => {
            this.lowlight.registerLanguage(languageName, language);
          })
          .catch(() => false);
      });

    return Promise.all(loaders);
  }
}
