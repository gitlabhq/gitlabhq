import {
  commandMapper,
  linksReducer,
  fileMapper,
} from '~/super_sidebar/components/global_search/command_palette/utils';
import { COMMANDS, LINKS, TRANSFORMED_LINKS } from './mock_data';

describe('linksReducer', () => {
  it('should transform links', () => {
    expect(LINKS.reduce(linksReducer, [])).toEqual(TRANSFORMED_LINKS);
  });
});

describe('commandMapper', () => {
  it('should temporarily remove the `invite_members` item', () => {
    const initialCommandsLength = COMMANDS[0].items.length;
    expect(COMMANDS.map(commandMapper)[0].items).toHaveLength(initialCommandsLength - 1);
  });
});

describe('fileMapper', () => {
  it('should transform files', () => {
    const file = 'file';
    const projectBlobPath = 'project/blob/path';
    expect(fileMapper(projectBlobPath, file)).toEqual({
      icon: 'doc-code',
      text: file,
      href: `${projectBlobPath}/${file}`,
      extraAttrs: {
        'data-track-action': 'click_command_palette_item',
        'data-track-label': 'file',
      },
    });
  });

  it('should encode file names with special characters', () => {
    const file = 'lua-amx_%.bbappend';
    const projectBlobPath = 'project/blob/path';
    expect(fileMapper(projectBlobPath, file)).toEqual({
      icon: 'doc-code',
      text: file,
      href: 'project/blob/path/lua-amx_%25.bbappend',
      extraAttrs: {
        'data-track-action': 'click_command_palette_item',
        'data-track-label': 'file',
      },
    });
  });
});
