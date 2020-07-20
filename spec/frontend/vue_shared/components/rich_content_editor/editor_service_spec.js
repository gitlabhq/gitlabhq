import {
  generateToolbarItem,
  addCustomEventListener,
  removeCustomEventListener,
  registerHTMLToMarkdownRenderer,
  addImage,
  getMarkdown,
} from '~/vue_shared/components/rich_content_editor/services/editor_service';
import buildHTMLToMarkdownRenderer from '~/vue_shared/components/rich_content_editor/services/build_html_to_markdown_renderer';

jest.mock('~/vue_shared/components/rich_content_editor/services/build_html_to_markdown_renderer');

describe('Editor Service', () => {
  let mockInstance;
  let event;
  let handler;

  beforeEach(() => {
    mockInstance = {
      eventManager: { addEventType: jest.fn(), removeEventHandler: jest.fn(), listen: jest.fn() },
      editor: { exec: jest.fn() },
      invoke: jest.fn(),
      toMarkOptions: {
        renderer: {
          constructor: {
            factory: jest.fn(),
          },
        },
      },
    };
    event = 'someCustomEvent';
    handler = jest.fn();
  });

  describe('generateToolbarItem', () => {
    const config = {
      icon: 'bold',
      command: 'some-command',
      tooltip: 'Some Tooltip',
      event: 'some-event',
    };

    const generatedItem = generateToolbarItem(config);

    it('generates the correct command', () => {
      expect(generatedItem.options.command).toBe(config.command);
    });

    it('generates the correct event', () => {
      expect(generatedItem.options.event).toBe(config.event);
    });

    it('generates a divider when isDivider is set to true', () => {
      const isDivider = true;

      expect(generateToolbarItem({ isDivider })).toBe('divider');
    });
  });

  describe('addCustomEventListener', () => {
    it('registers an event type on the instance and adds an event handler', () => {
      addCustomEventListener(mockInstance, event, handler);

      expect(mockInstance.eventManager.addEventType).toHaveBeenCalledWith(event);
      expect(mockInstance.eventManager.listen).toHaveBeenCalledWith(event, handler);
    });
  });

  describe('removeCustomEventListener', () => {
    it('removes an event handler from the instance', () => {
      removeCustomEventListener(mockInstance, event, handler);

      expect(mockInstance.eventManager.removeEventHandler).toHaveBeenCalledWith(event, handler);
    });
  });

  describe('addImage', () => {
    it('calls the exec method on the instance', () => {
      const mockImage = { imageUrl: 'some/url.png', description: 'some description' };

      addImage(mockInstance, mockImage);

      expect(mockInstance.editor.exec).toHaveBeenCalledWith('AddImage', mockImage);
    });
  });

  describe('getMarkdown', () => {
    it('calls the invoke method on the instance', () => {
      getMarkdown(mockInstance);

      expect(mockInstance.invoke).toHaveBeenCalledWith('getMarkdown');
    });
  });

  describe('registerHTMLToMarkdownRenderer', () => {
    let baseRenderer;
    const htmlToMarkdownRenderer = {};
    const extendedRenderer = {};

    beforeEach(() => {
      baseRenderer = mockInstance.toMarkOptions.renderer;
      buildHTMLToMarkdownRenderer.mockReturnValueOnce(htmlToMarkdownRenderer);
      baseRenderer.constructor.factory.mockReturnValueOnce(extendedRenderer);

      registerHTMLToMarkdownRenderer(mockInstance);
    });

    it('builds a new instance of the HTML to Markdown renderer', () => {
      expect(buildHTMLToMarkdownRenderer).toHaveBeenCalledWith(baseRenderer);
    });

    it('extends base renderer with the HTML to Markdown renderer', () => {
      expect(baseRenderer.constructor.factory).toHaveBeenCalledWith(
        baseRenderer,
        htmlToMarkdownRenderer,
      );
    });

    it('replaces the default renderer with extended renderer', () => {
      expect(mockInstance.toMarkOptions.renderer).toBe(extendedRenderer);
    });
  });
});
