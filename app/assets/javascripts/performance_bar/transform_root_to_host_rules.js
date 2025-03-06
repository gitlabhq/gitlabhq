export function transformRootToHostRules(shadowDomRoot) {
  if (!shadowDomRoot?.styleSheets?.length) {
    return;
  }
  let cssText = '';

  for (const sheet of shadowDomRoot.styleSheets) {
    for (const rule of sheet.cssRules) {
      if (rule instanceof CSSStyleRule && [':root', 'body'].includes(rule.selectorText)) {
        cssText += `:host {${rule.style.cssText}}\n`;
      }
    }
  }

  const newStyleSheet = new CSSStyleSheet();
  newStyleSheet.replaceSync(cssText);

  shadowDomRoot.adoptedStyleSheets.push(newStyleSheet);
}
