import MockAdapter from 'axios-mock-adapter';
import { Emitter } from 'monaco-editor';
import { useFakeRequestAnimationFrame } from 'helpers/fake_request_animation_frame';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import {
  EXTENSION_MARKDOWN_PREVIEW_PANEL_CLASS,
  EXTENSION_MARKDOWN_PREVIEW_ACTION_ID,
  EXTENSION_MARKDOWN_PREVIEW_PANEL_WIDTH,
  EXTENSION_MARKDOWN_PREVIEW_PANEL_PARENT_CLASS,
  EXTENSION_MARKDOWN_PREVIEW_UPDATE_DELAY,
} from '~/editor/constants';
import { EditorMarkdownPreviewExtension } from '~/editor/extensions/source_editor_markdown_livepreview_ext';
import SourceEditor from '~/editor/source_editor';
import { createAlert } from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import syntaxHighlight from '~/syntax_highlight';
import { spyOnApi } from './helpers';

jest.mock('~/syntax_highlight');
jest.mock('~/flash');

describe('Markdown Live Preview Extension for Source Editor', () => {
  let editor;
  let instance;
  let editorEl;
  let panelSpy;
  let mockAxios;
  let extension;
  const previewMarkdownPath = '/gitlab/fooGroup/barProj/preview_markdown';
  const firstLine = 'This is a';
  const secondLine = 'multiline';
  const thirdLine = 'string with some **markup**';
  const text = `${firstLine}\n${secondLine}\n${thirdLine}`;
  const markdownPath = 'foo.md';
  const responseData = '<div>FooBar</div>';

  const togglePreview = async () => {
    instance.togglePreview();
    await waitForPromises();
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    setHTMLFixture('<div id="editor" data-editor-loading></div>');
    editorEl = document.getElementById('editor');
    editor = new SourceEditor();
    instance = editor.createInstance({
      el: editorEl,
      blobPath: markdownPath,
      blobContent: text,
    });

    instance.toolbar = {
      addItems: jest.fn(),
      updateItem: jest.fn(),
      removeItems: jest.fn(),
    };

    extension = instance.use({
      definition: EditorMarkdownPreviewExtension,
      setupOptions: { previewMarkdownPath },
    });
    panelSpy = jest.spyOn(extension.obj.constructor.prototype, 'togglePreviewPanel');
  });

  afterEach(() => {
    instance.dispose();
    mockAxios.restore();
    resetHTMLFixture();
  });

  it('sets up the preview on the instance', () => {
    expect(instance.markdownPreview).toEqual({
      el: undefined,
      actions: expect.any(Object),
      shown: false,
      modelChangeListener: undefined,
      layoutChangeListener: {
        dispose: expect.anything(),
      },
      path: previewMarkdownPath,
      actionShowPreviewCondition: expect.any(Object),
      eventEmitter: expect.any(Object),
    });
  });

  it('support external preview trigger via emitter event', () => {
    expect(panelSpy).not.toHaveBeenCalled();

    instance.markdownPreview.eventEmitter.fire();

    expect(panelSpy).toHaveBeenCalled();
  });

  describe('onDidLayoutChange', () => {
    const emitter = new Emitter();
    let layoutSpy;

    useFakeRequestAnimationFrame();

    beforeEach(() => {
      instance.unuse(extension);
      instance.onDidLayoutChange = emitter.event;
      extension = instance.use({
        definition: EditorMarkdownPreviewExtension,
        setupOptions: { previewMarkdownPath },
      });
      layoutSpy = jest.spyOn(instance, 'layout');
    });

    it('does not trigger the layout when the preview is not active [default]', async () => {
      expect(instance.markdownPreview.shown).toBe(false);
      expect(layoutSpy).not.toHaveBeenCalled();
      await emitter.fire();
      expect(layoutSpy).not.toHaveBeenCalled();
    });

    it('triggers the layout if the preview panel is opened', async () => {
      expect(layoutSpy).not.toHaveBeenCalled();
      instance.togglePreview();
      layoutSpy.mockReset();

      await emitter.fire();
      expect(layoutSpy).toHaveBeenCalledTimes(1);
    });
  });

  describe('model change listener', () => {
    let cleanupSpy;
    let actionSpy;

    beforeEach(() => {
      cleanupSpy = jest.fn();
      actionSpy = jest.fn();
      spyOnApi(extension, {
        cleanup: cleanupSpy,
        setupPreviewAction: actionSpy,
      });
      instance.togglePreview();
    });

    afterEach(() => {
      jest.clearAllMocks();
    });

    it('does not do anything if there is no model', () => {
      instance.setModel(null);

      expect(cleanupSpy).not.toHaveBeenCalled();
      expect(actionSpy).not.toHaveBeenCalled();
    });
  });

  describe('onBeforeUnuse', () => {
    beforeEach(async () => {
      mockAxios.onPost().reply(200, { body: responseData });
      await togglePreview();
    });
    afterEach(() => {
      jest.clearAllMocks();
    });

    it('removes the registered buttons from the toolbar', () => {
      expect(instance.toolbar.removeItems).not.toHaveBeenCalled();
      instance.unuse(extension);
      expect(instance.toolbar.removeItems).toHaveBeenCalledWith([
        EXTENSION_MARKDOWN_PREVIEW_ACTION_ID,
      ]);
    });

    it('disposes the modelChange listener and does not fetch preview on content changes', () => {
      expect(instance.markdownPreview.modelChangeListener).toBeDefined();
      const fetchPreviewSpy = jest.fn();
      spyOnApi(extension, {
        fetchPreview: fetchPreviewSpy,
      });

      instance.unuse(extension);
      instance.setValue('Foo Bar');
      jest.advanceTimersByTime(EXTENSION_MARKDOWN_PREVIEW_UPDATE_DELAY);

      expect(fetchPreviewSpy).not.toHaveBeenCalled();
    });

    it('removes the contextual menu action', () => {
      expect(instance.getAction(EXTENSION_MARKDOWN_PREVIEW_ACTION_ID)).toBeDefined();

      instance.unuse(extension);

      expect(instance.getAction(EXTENSION_MARKDOWN_PREVIEW_ACTION_ID)).toBe(null);
    });

    it('toggles the panel only if the preview is visible', () => {
      const { el: previewEl } = instance.markdownPreview;
      const parentEl = previewEl.parentElement;

      expect(previewEl).toBeVisible();
      expect(parentEl.classList.contains(EXTENSION_MARKDOWN_PREVIEW_PANEL_PARENT_CLASS)).toBe(true);

      instance.unuse(extension);
      expect(previewEl).toBeHidden();
      expect(parentEl.classList.contains(EXTENSION_MARKDOWN_PREVIEW_PANEL_PARENT_CLASS)).toBe(
        false,
      );

      instance.unuse(extension);
      expect(previewEl).toBeHidden();
      expect(parentEl.classList.contains(EXTENSION_MARKDOWN_PREVIEW_PANEL_PARENT_CLASS)).toBe(
        false,
      );
    });

    it('toggles the layout only if the preview is visible', () => {
      const { width } = instance.getLayoutInfo();

      expect(instance.markdownPreview.shown).toBe(true);

      instance.unuse(extension);

      const { width: newWidth } = instance.getLayoutInfo();
      expect(newWidth === width / EXTENSION_MARKDOWN_PREVIEW_PANEL_WIDTH).toBe(true);

      instance.unuse(extension);
      expect(newWidth === width / EXTENSION_MARKDOWN_PREVIEW_PANEL_WIDTH).toBe(true);
    });

    it('disposes the layoutChange listener and does not re-layout on layout changes', () => {
      expect(instance.markdownPreview.layoutChangeListener).toBeDefined();
      instance.unuse(extension);

      expect(instance.markdownPreview?.layoutChangeListener).toBeUndefined();
    });

    it('does not trigger the re-layout after instance is unused', async () => {
      const emitter = new Emitter();

      instance.unuse(extension);
      instance.onDidLayoutChange = emitter.event;

      // we have to re-use the extension to pick up the emitter
      extension = instance.use({
        definition: EditorMarkdownPreviewExtension,
        setupOptions: { previewMarkdownPath },
      });
      instance.unuse(extension);
      const layoutSpy = jest.spyOn(instance, 'layout');

      await emitter.fire();
      expect(layoutSpy).not.toHaveBeenCalled();
    });
  });

  describe('fetchPreview', () => {
    const fetchPreview = async () => {
      instance.fetchPreview();
      await waitForPromises();
    };

    let previewMarkdownSpy;

    beforeEach(() => {
      previewMarkdownSpy = jest.fn().mockImplementation(() => [200, { body: responseData }]);
      mockAxios.onPost(previewMarkdownPath).replyOnce((req) => previewMarkdownSpy(req));
    });

    it('correctly fetches preview based on previewMarkdownPath', async () => {
      await fetchPreview();

      expect(previewMarkdownSpy).toHaveBeenCalledWith(
        expect.objectContaining({ data: JSON.stringify({ text }) }),
      );
    });

    it('puts the fetched content into the preview DOM element', async () => {
      instance.markdownPreview.el = editorEl.parentElement;
      await fetchPreview();
      expect(instance.markdownPreview.el.innerHTML).toEqual(responseData);
    });

    it('applies syntax highlighting to the preview content', async () => {
      instance.markdownPreview.el = editorEl.parentElement;
      await fetchPreview();
      expect(syntaxHighlight).toHaveBeenCalled();
    });

    it('catches the errors when fetching the preview', async () => {
      mockAxios.onPost().reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await fetchPreview();
      expect(createAlert).toHaveBeenCalled();
    });
  });

  describe('setupPreviewAction', () => {
    it('adds the contextual menu action', () => {
      expect(instance.getAction(EXTENSION_MARKDOWN_PREVIEW_ACTION_ID)).toBeDefined();
    });

    it('does not set up action if one already exists', () => {
      jest.spyOn(instance, 'addAction').mockImplementation();

      instance.setupPreviewAction();
      expect(instance.addAction).not.toHaveBeenCalled();
    });

    it('toggles preview when the action is triggered', () => {
      const togglePreviewSpy = jest.fn();
      spyOnApi(extension, {
        togglePreview: togglePreviewSpy,
      });

      expect(togglePreviewSpy).not.toHaveBeenCalled();

      const action = instance.getAction(EXTENSION_MARKDOWN_PREVIEW_ACTION_ID);
      action.run();

      expect(togglePreviewSpy).toHaveBeenCalled();
    });
  });

  describe('togglePreview', () => {
    beforeEach(() => {
      mockAxios.onPost().reply(200, { body: responseData });
    });

    it('toggles the condition to toggle preview/hide actions in the context menu', () => {
      expect(instance.markdownPreview.actionShowPreviewCondition.get()).toBe(true);
      instance.togglePreview();
      expect(instance.markdownPreview.actionShowPreviewCondition.get()).toBe(false);
    });

    it('toggles preview flag on instance', () => {
      expect(instance.markdownPreview.shown).toBe(false);

      instance.togglePreview();
      expect(instance.markdownPreview.shown).toBe(true);

      instance.togglePreview();
      expect(instance.markdownPreview.shown).toBe(false);
    });

    describe('panel DOM element set up', () => {
      it('sets up an element to contain the preview and stores it on instance', () => {
        expect(instance.markdownPreview.el).toBeUndefined();

        instance.togglePreview();

        expect(instance.markdownPreview.el).toBeDefined();
        expect(
          instance.markdownPreview.el.classList.contains(EXTENSION_MARKDOWN_PREVIEW_PANEL_CLASS),
        ).toBe(true);
      });

      it('re-uses existing preview DOM element on repeated calls', () => {
        instance.togglePreview();
        const origPreviewEl = instance.markdownPreview.el;
        instance.togglePreview();

        expect(instance.markdownPreview.el).toBe(origPreviewEl);
      });

      it('hides the preview DOM element by default', () => {
        panelSpy.mockImplementation();
        instance.togglePreview();
        expect(instance.markdownPreview.el.style.display).toBe('none');
      });
    });

    describe('preview layout setup', () => {
      it('sets correct preview layout', () => {
        jest.spyOn(instance, 'layout');
        const { width, height } = instance.getLayoutInfo();

        instance.togglePreview();

        expect(instance.layout).toHaveBeenCalledWith({
          width: width * EXTENSION_MARKDOWN_PREVIEW_PANEL_WIDTH,
          height,
        });
      });
    });

    describe('preview panel', () => {
      it('toggles preview CSS class on the editor', () => {
        expect(editorEl.classList.contains(EXTENSION_MARKDOWN_PREVIEW_PANEL_PARENT_CLASS)).toBe(
          false,
        );
        instance.togglePreview();
        expect(editorEl.classList.contains(EXTENSION_MARKDOWN_PREVIEW_PANEL_PARENT_CLASS)).toBe(
          true,
        );
        instance.togglePreview();
        expect(editorEl.classList.contains(EXTENSION_MARKDOWN_PREVIEW_PANEL_PARENT_CLASS)).toBe(
          false,
        );
      });

      it('toggles visibility of the preview DOM element', async () => {
        await togglePreview();
        expect(instance.markdownPreview.el.style.display).toBe('block');
        await togglePreview();
        expect(instance.markdownPreview.el.style.display).toBe('none');
      });

      describe('hidden preview DOM element', () => {
        it('listens to model changes and re-fetches preview', async () => {
          expect(mockAxios.history.post).toHaveLength(0);
          await togglePreview();
          expect(mockAxios.history.post).toHaveLength(1);

          instance.setValue('New Value');
          await waitForPromises();
          expect(mockAxios.history.post).toHaveLength(2);
        });

        it('stores disposable listener for model changes', async () => {
          expect(instance.markdownPreview.modelChangeListener).toBeUndefined();
          await togglePreview();
          expect(instance.markdownPreview.modelChangeListener).toBeDefined();
        });
      });

      describe('already visible preview', () => {
        beforeEach(async () => {
          await togglePreview();
          mockAxios.resetHistory();
        });

        it('does not re-fetch the preview', () => {
          instance.togglePreview();
          expect(mockAxios.history.post).toHaveLength(0);
        });

        it('disposes the model change event listener', () => {
          const disposeSpy = jest.fn();
          instance.markdownPreview.modelChangeListener = {
            dispose: disposeSpy,
          };
          instance.togglePreview();
          expect(disposeSpy).toHaveBeenCalled();
        });
      });
    });
  });
});
