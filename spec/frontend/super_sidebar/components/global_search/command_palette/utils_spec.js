import {
  userMapper,
  commandMapper,
} from '~/super_sidebar/components/global_search/command_palette/utils';
import { COMMANDS, USERS } from './mock_data';

describe('userMapper', () => {
  it('should transform users response', () => {
    const user = USERS[0];
    expect(userMapper(user)).toEqual({
      id: user.id,
      username: user.username,
      text: user.name,
      href: user.web_url,
      avatar_url: user.avatar_url,
    });
  });
});

describe('commandMapper', () => {
  it('should transform commands response', () => {
    const command = COMMANDS[0];
    expect(commandMapper(command)).toEqual({
      href: command.href,
      text: command.text,
      keywords: command.keywords.join(''),
    });
  });
});
