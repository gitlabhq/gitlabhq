import { generateToolbarItem } from '~/vue_shared/components/rich_content_editor/toolbar_service';

describe('Toolbar Service', () => {
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
