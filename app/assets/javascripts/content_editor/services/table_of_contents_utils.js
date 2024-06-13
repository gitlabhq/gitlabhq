class TOCHeading {
  parent = null;
  subHeadings = [];

  constructor(text) {
    this.text = text;
  }

  get level() {
    return this.parent ? this.parent.level + 1 : 0;
  }

  addSubHeading(text) {
    const heading = new TOCHeading(text);
    heading.parent = this;
    this.subHeadings.push(heading);
    return heading;
  }

  parentAt(level) {
    let parentNode = this;

    while (parentNode.level > level) {
      parentNode = parentNode.parent;
    }

    return parentNode;
  }

  flattenIfEmpty() {
    this.subHeadings.forEach((subHeading) => {
      subHeading.flattenIfEmpty();
    });

    if (!this.text && this.parent) {
      const index = this.parent.subHeadings.indexOf(this);
      this.parent.subHeadings.splice(index, 1, ...this.subHeadings);
      for (const subHeading of this.subHeadings) {
        subHeading.parent = this.parent;
      }
    }

    return this;
  }

  toJSON() {
    return {
      text: this.text,
      level: this.level,
      subHeadings: this.subHeadings.map((subHeading) => subHeading.toJSON()),
    };
  }
}

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

export function toTree(headings) {
  fillEmpty(headings);

  const tree = new TOCHeading();
  let currentHeading = tree;

  for (const heading of headings) {
    if (heading.level <= currentHeading.level) {
      currentHeading = currentHeading.parentAt(heading.level - 1);
    }
    currentHeading = (currentHeading || tree).addSubHeading(heading.text);
  }

  return tree.flattenIfEmpty().toJSON();
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

  return toTree(headings).subHeadings;
}
