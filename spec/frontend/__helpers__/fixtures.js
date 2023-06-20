export const resetHTMLFixture = () => {
  document.head.innerHTML = '';
  document.body.innerHTML = '';
};

export const setHTMLFixture = (htmlContent) => {
  document.body.innerHTML = htmlContent;
};
