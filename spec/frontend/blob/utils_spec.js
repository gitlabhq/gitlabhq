import * as utils from '~/blob/utils';
import Editor from '~/editor/source_editor';

jest.mock('~/editor/source_editor');

describe('Blob utilities', () => {
  describe('initSourceEditor', () => {
    let editorEl;
    const blobPath = 'foo.txt';
    const blobContent = 'Foo bar';
    const blobGlobalId = 'snippet_777';

    beforeEach(() => {
      editorEl = document.createElement('div');
    });

    describe('Monaco editor', () => {
      it('initializes the Source Editor', () => {
        utils.initSourceEditor({ el: editorEl });
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

          utils.initSourceEditor(params);

          expect(Editor.prototype.createInstance).toHaveBeenCalledWith(params);
        },
      );
    });
  });
});
