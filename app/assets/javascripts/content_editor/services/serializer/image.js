import { pickBy, identity } from 'lodash';
import { preserveUnchanged, openTag } from '../serialization_helpers';

function getMediaSrc(node, useCanonicalSrc = true) {
  const { canonicalSrc, src } = node.attrs;

  if (useCanonicalSrc) return canonicalSrc || src || '';
  return src || '';
}

const image = preserveUnchanged({
  render: (state, node) => {
    const { alt, title, width, height, isReference, sourceMarkdown, sourceTagName } = node.attrs;

    const realSrc = getMediaSrc(node, state.options.useCanonicalSrc);
    // eslint-disable-next-line @gitlab/require-i18n-strings
    if (realSrc.startsWith('data:') || realSrc.startsWith('blob:')) return;

    if (realSrc) {
      if (sourceTagName === 'img' && !sourceMarkdown) {
        const attrs = pickBy({ alt, title, width, height }, identity);
        state.write(openTag(sourceTagName, { src: realSrc, ...attrs }));
        return;
      }
      const quotedTitle = title ? ` ${state.quote(title)}` : '';
      const sourceExpression = isReference ? `[${realSrc}]` : `(${realSrc}${quotedTitle})`;

      const sizeAttributes = [];
      if (width) {
        sizeAttributes.push(`width=${JSON.stringify(width)}`);
      }
      if (height) {
        sizeAttributes.push(`height=${JSON.stringify(height)}`);
      }

      const attributes = sizeAttributes.length ? `{${sizeAttributes.join(' ')}}` : '';

      state.write(`![${state.esc(alt || '')}]${sourceExpression}${attributes}`);
    }
  },
  inline: true,
});

export default image;
