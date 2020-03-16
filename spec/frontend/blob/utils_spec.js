import Editor from '~/editor/editor_lite';
import * as utils from '~/blob/utils';

const mockCreateMonacoInstance = jest.fn();
jest.mock('~/editor/editor_lite', () => {
  return jest.fn().mockImplementation(() => {
    return { createInstance: mockCreateMonacoInstance };
  });
});

const mockCreateAceInstance = jest.fn();
global.ace = {
  edit: mockCreateAceInstance,
};

describe('Blob utilities', () => {
  beforeEach(() => {
    Editor.mockClear();
  });

  describe('initEditorLite', () => {
    let editorEl;
    const blobPath = 'foo.txt';
    const blobContent = 'Foo bar';

    beforeEach(() => {
      setFixtures('<div id="editor"></div>');
      editorEl = document.getElementById('editor');
    });

    describe('Monaco editor', () => {
      let origProp;

      beforeEach(() => {
        origProp = window.gon;
        window.gon = {
          features: {
            monacoSnippets: true,
          },
        };
      });

      afterEach(() => {
        window.gon = origProp;
      });

      it('initializes the Editor Lite', () => {
        utils.initEditorLite({ el: editorEl });
        expect(Editor).toHaveBeenCalled();
      });

      it('creates the instance with the passed parameters', () => {
        utils.initEditorLite({ el: editorEl });
        expect(mockCreateMonacoInstance.mock.calls[0]).toEqual([
          {
            el: editorEl,
            blobPath: undefined,
            blobContent: undefined,
          },
        ]);

        utils.initEditorLite({ el: editorEl, blobPath, blobContent });
        expect(mockCreateMonacoInstance.mock.calls[1]).toEqual([
          {
            el: editorEl,
            blobPath,
            blobContent,
          },
        ]);
      });
    });
    describe('ACE editor', () => {
      let origProp;

      beforeEach(() => {
        origProp = window.gon;
        window.gon = {
          features: {
            monacoSnippets: false,
          },
        };
      });

      afterEach(() => {
        window.gon = origProp;
      });

      it('does not initialize the Editor Lite', () => {
        utils.initEditorLite({ el: editorEl });
        expect(Editor).not.toHaveBeenCalled();
        expect(mockCreateAceInstance).toHaveBeenCalledWith(editorEl);
      });
    });
  });
});
