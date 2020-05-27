import {
  generateToolbarItem,
  addCustomEventListener,
} from '~/vue_shared/components/rich_content_editor/editor_service';

describe('Editor Service', () => {
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

    it('generates the correct tooltip', () => {
      expect(generatedItem.options.tooltip).toBe(config.tooltip);
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
    const mockInstance = { eventManager: { addEventType: jest.fn(), listen: jest.fn() } };
    const event = 'someCustomEvent';
    const handler = jest.fn();

    it('registers an event type on the instance and adds an event handler', () => {
      addCustomEventListener(mockInstance, event, handler);

      expect(mockInstance.eventManager.addEventType).toHaveBeenCalledWith(event);
      expect(mockInstance.eventManager.listen).toHaveBeenCalledWith(event, handler);
    });
  });
});
