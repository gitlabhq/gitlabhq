import { parseConfig } from '~/glql/core/parser/config';

describe('parseConfig', () => {
  it('parses the frontmatter and returns an object', () => {
    const frontmatter = 'fields: title, assignees, dueDate\ndisplay: list';

    expect(parseConfig(frontmatter)).toEqual({
      fields: [
        { name: 'title', label: 'Title', key: 'title' },
        { name: 'assignees', label: 'Assignees', key: 'assignees' },
        { name: 'dueDate', label: 'Due date', key: 'dueDate' },
      ],
      display: 'list',
    });
  });

  it('returns default fields if none are provided', () => {
    const frontmatter = 'display: list';

    expect(parseConfig(frontmatter, { fields: ['title', 'assignees', 'dueDate'] })).toEqual({
      fields: [
        { name: 'title', label: 'Title', key: 'title' },
        { name: 'assignees', label: 'Assignees', key: 'assignees' },
        { name: 'dueDate', label: 'Due date', key: 'dueDate' },
      ],
      display: 'list',
    });
  });
});
