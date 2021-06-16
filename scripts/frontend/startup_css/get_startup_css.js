const fs = require('fs');
const cheerio = require('cheerio');
const { mergeWith, isArray } = require('lodash');
const { PurgeCSS } = require('purgecss');
const purgeHtml = require('purgecss-from-html');
const { cleanCSS } = require('./clean_css');
const { HTML_TO_REMOVE } = require('./constants');
const { die } = require('./utils');

const cleanHtml = (html) => {
  const $ = cheerio.load(html);

  HTML_TO_REMOVE.forEach((selector) => {
    $(selector).remove();
  });

  return $.html();
};

const mergePurgeCSSOptions = (...options) =>
  mergeWith(...options, (objValue, srcValue) => {
    if (isArray(objValue)) {
      return objValue.concat(srcValue);
    }

    return undefined;
  });

const getStartupCSS = async ({ htmlPaths, cssPaths, purgeOptions }) => {
  const content = htmlPaths.map((htmlPath) => {
    if (!fs.existsSync(htmlPath)) {
      die(`Could not find fixture "${htmlPath}". Have you run the fixtures?`);
    }

    const rawHtml = fs.readFileSync(htmlPath);
    const html = cleanHtml(rawHtml);

    return { raw: html, extension: 'html' };
  });

  const purgeCSSResult = await new PurgeCSS().purge({
    content,
    css: cssPaths,
    ...mergePurgeCSSOptions(
      {
        fontFace: true,
        variables: true,
        keyframes: true,
        blocklist: [/:hover/, /:focus/, /-webkit-/, /-moz-focusring-/, /-ms-expand/],
        safelist: {
          standard: ['brand-header-logo'],
        },
        // By default, PurgeCSS ignores special characters, but our utilities use "!"
        defaultExtractor: (x) => x.match(/[\w-!]+/g),
        extractors: [
          {
            extractor: purgeHtml,
            extensions: ['html'],
          },
        ],
      },
      purgeOptions,
    ),
  });

  return purgeCSSResult.map(({ css }) => cleanCSS(css)).join('\n');
};

module.exports = { getStartupCSS };
