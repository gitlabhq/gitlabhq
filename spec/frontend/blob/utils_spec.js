import * as utils from '~/blob/utils';
import Editor from '~/editor/editor_lite';

jest.mock('~/editor/editor_lite');

describe('Blob utilities', () => {
  describe('initEditorLite', () => {
    let editorEl;
    const blobPath = 'foo.txt';
    const blobContent = 'Foo bar';
    const blobGlobalId = 'snippet_777';

    beforeEach(() => {
      editorEl = document.createElement('div');
    });

    describe('Monaco editor', () => {
      it('initializes the Editor Lite', () => {
        utils.initEditorLite({ el: editorEl });
        expect(Editor).toHaveBeenCalledWith({
          scrollbar: {
            alwaysConsumeMouseWheel: false,
          },
        });
      });

      it.each([[{}], [{ blobPath, blobContent, blobGlobalId }]])(
        'creates the instance with the passed parameters %s',
        (extraParams) => {
          const params = {
            el: editorEl,
            ...extraParams,
          };

          expect(Editor.prototype.createInstance).not.toHaveBeenCalled();

          utils.initEditorLite(params);

          expect(Editor.prototype.createInstance).toHaveBeenCalledWith(params);
        },
      );
    });
  });
});
