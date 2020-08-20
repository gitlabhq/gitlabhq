export default {
  toHaveSpriteIcon: (element, iconName) => {
    if (!iconName) {
      throw new Error('toHaveSpriteIcon is missing iconName argument!');
    }

    if (!(element instanceof HTMLElement)) {
      throw new Error(`${element} is not a DOM element!`);
    }

    const iconReferences = [].slice.apply(element.querySelectorAll('svg use'));
    const matchingIcon = iconReferences.find(
      reference => reference.parentNode.getAttribute('data-testid') === `${iconName}-icon`,
    );

    const pass = Boolean(matchingIcon);

    let message;
    if (pass) {
      message = `${element.outerHTML} contains the sprite icon "${iconName}"!`;
    } else {
      message = `${element.outerHTML} does not contain the sprite icon "${iconName}"!`;

      const existingIcons = iconReferences.map(reference => {
        const iconUrl = reference.getAttribute('href');
        return `"${iconUrl.replace(/^.+#/, '')}"`;
      });
      if (existingIcons.length > 0) {
        message += ` (only found ${existingIcons.join(',')})`;
      }
    }

    return {
      pass,
      message: () => message,
    };
  },
  toMatchInterpolatedText(received, match) {
    let clearReceived;
    let clearMatch;

    try {
      clearReceived = received
        .replace(/\s\s+/gm, ' ')
        .replace(/\s\./gm, '.')
        .trim();
    } catch (e) {
      return { actual: received, message: 'The received value is not a string', pass: false };
    }
    try {
      clearMatch = match.replace(/%{\w+}/gm, '').trim();
    } catch (e) {
      return { message: 'The comparator value is not a string', pass: false };
    }
    const pass = clearReceived === clearMatch;
    const message = pass
      ? () => `
          \n\n
          Expected: ${this.utils.printExpected(clearReceived)}
          To not equal: ${this.utils.printReceived(clearMatch)}
          `
      : () =>
          `
        \n\n
        Expected: ${this.utils.printExpected(clearReceived)}
        To equal: ${this.utils.printReceived(clearMatch)}
        `;

    return { actual: received, message, pass };
  },
};
