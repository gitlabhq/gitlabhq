import * as Blockquote from '~/content_editor/extensions/blockquote';
import * as Bold from '~/content_editor/extensions/bold';
import * as Dropcursor from '~/content_editor/extensions/dropcursor';
import * as Paragraph from '~/content_editor/extensions/paragraph';

import buildSerializerConfig from '~/content_editor/services/build_serializer_config';

describe('content_editor/services/build_serializer_config', () => {
  describe('given one or more content editor extensions', () => {
    it('creates a serializer config that collects all extension serializers by type', () => {
      const extensions = [Bold, Blockquote, Paragraph];
      const serializerConfig = buildSerializerConfig(extensions);

      extensions.forEach(({ tiptapExtension, serializer }) => {
        const { name, type } = tiptapExtension;
        expect(serializerConfig[`${type}s`][name]).toBe(serializer);
      });
    });
  });

  describe('given an extension without serializer', () => {
    it('does not include the extension in the serializer config', () => {
      const serializerConfig = buildSerializerConfig([Dropcursor]);

      expect(serializerConfig.marks[Dropcursor.tiptapExtension.name]).toBe(undefined);
      expect(serializerConfig.nodes[Dropcursor.tiptapExtension.name]).toBe(undefined);
    });
  });

  describe('given no extensions', () => {
    it('creates an empty serializer config', () => {
      expect(buildSerializerConfig()).toStrictEqual({
        marks: {},
        nodes: {},
      });
    });
  });
});
