import { Emitter } from 'monaco-editor';
import { setHTMLFixture } from 'helpers/fixtures';
import { EditorWebIdeExtension } from '~/editor/extensions/source_editor_webide_ext';
import SourceEditor from '~/editor/source_editor';

describe('Source Editor Web IDE Extension', () => {
  let editorEl;
  let editor;
  let instance;

  beforeEach(() => {
    setHTMLFixture('<div id="editor" data-editor-loading></div>');
    editorEl = document.getElementById('editor');
    editor = new SourceEditor();
  });

  describe('onSetup', () => {
    it.each`
      width      | renderSideBySide
      ${'0'}     | ${false}
      ${'699px'} | ${false}
      ${'700px'} | ${true}
    `(
      "correctly renders the Diff Editor when the parent element's width is $width",
      ({ width, renderSideBySide }) => {
        editorEl.style.width = width;
        instance = editor.createDiffInstance({ el: editorEl });

        const sideBySideSpy = jest.spyOn(instance, 'updateOptions');
        instance.use({ definition: EditorWebIdeExtension });

        expect(sideBySideSpy).toHaveBeenCalledWith({ renderSideBySide });
      },
    );

    it('re-renders the Diff Editor when layout of the modified editor is changed', async () => {
      const emitter = new Emitter();
      editorEl.style.width = '700px';

      instance = editor.createDiffInstance({ el: editorEl });
      instance.getModifiedEditor().onDidLayoutChange = emitter.event;
      instance.use({ definition: EditorWebIdeExtension });

      const sideBySideSpy = jest.spyOn(instance, 'updateOptions');
      await emitter.fire();

      expect(sideBySideSpy).toHaveBeenCalledWith({ renderSideBySide: true });

      editorEl.style.width = '0px';
      await emitter.fire();
      expect(sideBySideSpy).toHaveBeenCalledWith({ renderSideBySide: false });
    });
  });
});
