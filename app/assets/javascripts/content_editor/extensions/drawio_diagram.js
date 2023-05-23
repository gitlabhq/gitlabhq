import { create } from '~/drawio/content_editor_facade';
import { launchDrawioEditor } from '~/drawio/drawio_editor';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';
import Image from './image';

export default Image.extend({
  name: 'drawioDiagram',
  addOptions() {
    return {
      ...this.parent?.(),
      uploadsPath: null,
      assetResolver: null,
    };
  },
  parseHTML() {
    return [
      {
        priority: PARSE_HTML_PRIORITY_HIGHEST,
        tag: 'a.no-attachment-icon[data-canonical-src$="drawio.svg"]',
      },
      {
        tag: 'img[src]',
      },
    ];
  },
  addCommands() {
    return {
      createOrEditDiagram: () => () => {
        launchDrawioEditor({
          editorFacade: create({
            tiptapEditor: this.editor,
            drawioNodeName: this.name,
            uploadsPath: this.options.uploadsPath,
            assetResolver: this.options.assetResolver,
          }),
        });
      },
    };
  },
});
