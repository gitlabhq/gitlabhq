import { MarkdownSerializer, defaultMarkdownSerializer } from 'prosemirror-markdown';

const defaultNodes = defaultMarkdownSerializer.nodes;
const nodes = {
  /*
  blockquote
  code_block
  heading
  horizontal_rule
  bullet_list
  ordered_list
  list_item
  paragraph
  image
  hard_break
  text
  */
  ...defaultNodes,
  video(state, node) {
    state.write("![" + state.esc(node.attrs.alt || "") + "](" + state.esc(node.attrs.src) + ")");
    state.closeBlock(node);
  },
  emoji(state, node) {
    state.write(`:${node.attrs.name}:`);
  },
  reference(state, node) {
    state.write(node.attrs.originalText || node.attrs.text);
  },
  code_block(state, node) {
    const text = node.textContent;
    const lang = node.attrs.lang;
    // Prefixes lines with 4 spaces if the code contains a line that starts with triple backticks
    if (lang == '' && text.match(/^```/gm)) {
      state.wrapBlock("    ", null, node, () => state.text(text, false));
    } else {
      state.write("```" + lang + "\n");
      state.text(text, false);
      state.ensureNewLine();
      state.write("```");
      state.closeBlock(node);
    }
  },
  hard_break(state, node) {
    if (!state.atBlank()) state.write("  \n");
  },
  math(state, node) {
    state.write("$`");
    state.text(node.textContent, false);
    state.write("`$");
  },
  code(state, node) {
    const text = node.textContent;

    let backtickCount = 1;
    const backtickMatch = text.match(/`+/);
    if (backtickMatch) {
      backtickCount = backtickMatch[0].length + 1;
    }

    const backticks = Array(backtickCount + 1).join('`');
    const spaceOrNoSpace = backtickCount > 1 ? ' ' : '';

    state.write(backticks + spaceOrNoSpace);
    state.text(text, false);
    state.write(spaceOrNoSpace + backticks);
  },
  html(state, node) {
    state.write(`<${node.attrs.tag}>\n`);
    state.renderContent(node);
    state.ensureNewLine();
    state.write(`</${node.attrs.tag}>`);
    state.closeBlock(node);
  },
  details(state, node) {
    state.write("<details>\n");
    state.renderContent(node);
    state.ensureNewLine();
    state.write('</details>');
    state.closeBlock(node);
  },
  summary(state, node) {
    state.write('<summary>');
    state.text(node.textContent, false);
    state.write('</summary>');
    state.closeBlock(node);
  },
}

const defaultMarks = defaultMarkdownSerializer.marks;
const marks = {
  ...defaultMarks, // em strong link code
  bold: defaultMarks.strong,
  italic: defaultMarks.em,
  math: { open: '$`', close: '`$', escape: false }, // prosemirror-markdown bug: open/close are reversed!
  strike: { open: "~~", close: "~~", mixable: true, expelEnclosingWhitespace: true },
  inline_diff: {
    mixable: true,
    open(state, mark) {
      return mark.attrs.addition ? '{+' : '{-';
    },
    close(state, mark) {
      return mark.attrs.addition ? '+}' : '-}';
    }
  },
  inline_html: {
    mixable: true,
    open(state, mark) {
      return `<${mark.attrs.tag}${mark.attrs.title ? ` title="${state.esc(mark.attrs.title)}"` : ''}>`;
    },
    close(state, mark) {
      return `</${mark.attrs.tag}>`;
    }
  },
}

export default new MarkdownSerializer(nodes, marks);
