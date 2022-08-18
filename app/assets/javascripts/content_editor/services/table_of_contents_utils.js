export function fillEmpty(headings) {
  for (let i = 0; i < headings.length; i += 1) {
    let j = headings[i - 1]?.level || 0;
    if (headings[i].level - j > 1) {
      while (j < headings[i].level) {
        headings.splice(i, 0, { level: j + 1, text: '' });
        j += 1;
      }
    }
  }

  return headings;
}

const exitHeadingBranch = (heading, targetLevel) => {
  let currentHeading = heading;

  while (currentHeading.level > targetLevel) {
    currentHeading = currentHeading.parent;
  }

  return currentHeading;
};

export function toTree(headings) {
  fillEmpty(headings);

  const tree = [];
  let currentHeading;
  for (let i = 0; i < headings.length; i += 1) {
    const heading = headings[i];
    if (heading.level === 1) {
      const h = { ...heading, subHeadings: [] };
      tree.push(h);
      currentHeading = h;
    } else if (heading.level > currentHeading.level) {
      const h = { ...heading, subHeadings: [], parent: currentHeading };
      currentHeading.subHeadings.push(h);
      currentHeading = h;
    } else if (heading.level <= currentHeading.level) {
      currentHeading = exitHeadingBranch(currentHeading, heading.level - 1);

      const h = { ...heading, subHeadings: [], parent: currentHeading };
      (currentHeading?.subHeadings || headings).push(h);
      currentHeading = h;
    }
  }

  return tree;
}

export function getHeadings(editor) {
  const headings = [];

  editor.state.doc.descendants((node) => {
    if (node.type.name !== 'heading') return false;

    headings.push({
      level: node.attrs.level,
      text: node.textContent,
    });

    return true;
  });

  return toTree(headings);
}
