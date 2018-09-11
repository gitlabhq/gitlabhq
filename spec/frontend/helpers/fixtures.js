import fs from 'fs';

const readFixtureFile = filePath =>
  fs.readFileSync(`spec/javascripts/fixtures/${filePath}`, 'utf8');

export const resetHTMLFixture = () => {
  document.body.textContent = '';
};

export const setHTMLFixture = (htmlContent, resetHook = afterEach) => {
  document.body.outerHTML = htmlContent;
  resetHook(resetHTMLFixture);
};

export const loadHTMLFixture = (filePath, resetHook = afterEach) => {
  const fileContent = readFixtureFile(filePath);
  setHTMLFixture(fileContent, resetHook);
};

export const getJSONFixture = filePath => {
  const fileContent = readFixtureFile(filePath);
  return JSON.parse(fileContent);
};
