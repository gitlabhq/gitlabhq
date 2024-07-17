import { defaultMarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';

const mathInline = {
  open: (...args) => `$${defaultMarkdownSerializer.marks.code.open(...args)}`,
  close: (...args) => `${defaultMarkdownSerializer.marks.code.close(...args)}$`,
  escape: false,
};

export default mathInline;
