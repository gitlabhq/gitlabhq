const MARKDOWN_EXTENSIONS = ['md', 'markdown', 'mkd', 'mkdn', 'mdown', 'rmd'];

export const isMarkdownFilePath = (path) =>
  MARKDOWN_EXTENSIONS.some((ext) => path?.toLowerCase().endsWith(`.${ext}`));

export default () => ({});
