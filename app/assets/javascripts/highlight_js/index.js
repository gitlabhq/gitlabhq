import hljsCore from 'highlight.js/lib/core';
import languageLoader from '~/content_editor/services/highlight_js_language_loader';
import { ROUGE_TO_HLJS_LANGUAGE_MAP } from '~/vue_shared/components/source_viewer/constants';
import { registerPlugins } from './plugins/index';

const loadLanguage = async (language, hljs) => {
  const languageDefinition = await languageLoader[language]();
  if (Array.isArray(languageDefinition)) {
    languageDefinition.forEach(([languageDependency, languageDependencyDefinition]) =>
      hljs.registerLanguage(languageDependency, languageDependencyDefinition.default),
    );
  } else {
    hljs.registerLanguage(language, languageDefinition.default);
  }
};

// Highlight.js's Markdown grammar does not recognize YAML frontmatter, so the
// closing `---` delimiter pairs with the preceding line and is highlighted as a
// Setext heading. Inject a frontmatter mode, anchored to the start of the
// document, so the block is highlighted as YAML instead.
const patchMarkdownFrontmatter = (hljs) => {
  const markdown = hljs.getLanguage('markdown');
  if (!markdown?.contains) return;

  markdown.contains.unshift({
    className: 'meta',
    begin: /(?<![\s\S])---\s*$/, // matches only at the start of the document
    end: /^---\s*$/,
    subLanguage: 'yaml',
  });
};

const loadSubLanguages = async (languageDefinition, hljs) => {
  // Some files can contain sub-languages (i.e., Svelte); this ensures that sub-languages are also loaded
  if (!languageDefinition?.contains) return;

  // generate list of languages to load
  const languages = new Set(
    languageDefinition.contains
      .filter((component) => Boolean(component.subLanguage))
      .map((component) => component.subLanguage),
  );

  if (languageDefinition.subLanguage) {
    languages.add(languageDefinition.subLanguage);
  }

  await Promise.all([...languages].map((language) => loadLanguage(language, hljs)));
};

const registerLanguage = async (hljs, language) => {
  await loadLanguage(language, hljs);

  if (language === 'markdown') {
    patchMarkdownFrontmatter(hljs);
  }

  await loadSubLanguages(hljs.getLanguage(language), hljs);
};

const initHighlightJs = async (language, plugins) => {
  const hljs = hljsCore.newInstance();

  registerPlugins(hljs, plugins);
  await registerLanguage(hljs, language);

  return hljs;
};

const highlightContent = async (lang, rawContent, plugins) => {
  const language = ROUGE_TO_HLJS_LANGUAGE_MAP[lang.toLowerCase()];
  let highlightedContent;

  if (language) {
    const hljs = await initHighlightJs(language, plugins);
    highlightedContent = hljs.highlight(rawContent, { language }).value;
  }

  return highlightedContent;
};

export { highlightContent };
