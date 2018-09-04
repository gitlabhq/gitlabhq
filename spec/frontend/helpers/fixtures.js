import fs from 'fs';

export const resetHTMLFixture = () => {
  document.body.textContent = '';
};

export const setHTMLFixture = (htmlContent, resetHook = afterEach) => {
  document.body.outerHTML = htmlContent;
  resetHook(resetHTMLFixture);
};

export const loadHTMLFixture = (filePath, resetHook = afterEach) => {
  const fileContent = fs.readFileSync(`spec/javascripts/fixtures/${filePath}`, 'utf8');
  setHTMLFixture(fileContent, resetHook);
};
