import { DOMSerializer } from '@tiptap/pm/model';
import HTMLComment from '~/content_editor/extensions/html_comment';
import { createTestEditor } from '../test_utils';

describe('content_editor/extensions/html_comment', () => {
  let tiptapEditor;

  const serializeToHTML = () => {
    const container = document.createElement('div');

    container.appendChild(
      DOMSerializer.fromSchema(tiptapEditor.schema).serializeFragment(
        tiptapEditor.state.doc.content,
      ),
    );

    return container.innerHTML;
  };

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [HTMLComment] });
  });

  it('parses the comment element the markdown deserializer produces', () => {
    tiptapEditor.commands.setContent('<comment> my comment &#x000A; </comment><p>text</p>');

    expect(tiptapEditor.getJSON().content[0]).toEqual({
      type: 'htmlComment',
      attrs: { description: 'my comment' },
    });
  });

  it('renders the comment as an element without visible text', () => {
    tiptapEditor.commands.setContent('<comment>my comment</comment><p>text</p>');

    expect(serializeToHTML()).toBe(
      '<comment data-description="my comment"></comment><p dir="auto">text</p>',
    );
  });

  it('parses its own rendered element back to the same node', () => {
    tiptapEditor.commands.setContent('<comment data-description="my comment"></comment>');

    expect(tiptapEditor.getJSON().content[0]).toEqual({
      type: 'htmlComment',
      attrs: { description: 'my comment' },
    });
  });
});
