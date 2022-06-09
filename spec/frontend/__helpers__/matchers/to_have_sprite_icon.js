export const toHaveSpriteIcon = (element, iconName) => {
  if (!iconName) {
    throw new Error('toHaveSpriteIcon is missing iconName argument!');
  }

  if (!(element instanceof HTMLElement)) {
    throw new Error(`${element} is not a DOM element!`);
  }

  const iconReferences = [].slice.apply(element.querySelectorAll('svg use'));
  const matchingIcon = iconReferences.find(
    (reference) => reference.parentNode.dataset.testid === `${iconName}-icon`,
  );

  const pass = Boolean(matchingIcon);

  let message;
  if (pass) {
    message = `${element.outerHTML} contains the sprite icon "${iconName}"!`;
  } else {
    message = `${element.outerHTML} does not contain the sprite icon "${iconName}"!`;

    const existingIcons = iconReferences.map((reference) => {
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
};
