import { extractGroupOrProject, parseQueryText, parseFrontmatter } from '~/glql/utils/common';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';

describe('extractGroupOrProject', () => {
  useMockLocationHelper();

  it.each`
    url                                                            | group                       | project
    ${'https://gitlab.com/gitlab-org/gitlab-test/-/issues'}        | ${undefined}                | ${'gitlab-org/gitlab-test'}
    ${'https://gitlab.com/groups/gitlab-org/-/issues'}             | ${'gitlab-org'}             | ${undefined}
    ${'https://gitlab.com/groups/gitlab-org/gitlab-test/-/issues'} | ${'gitlab-org/gitlab-test'} | ${undefined}
  `('returns the correct group or project', ({ url, group, project }) => {
    window.location.origin = 'https://gitlab.com';

    window.location.href = url;
    expect(extractGroupOrProject()).toEqual({ group, project });
  });

  it('removes gon.relative_url_root from the URL before parsing', () => {
    window.location.origin = 'https://gitlab.com';
    window.location.href = 'https://gitlab.com/gitlab/groups/gitlab-org/-/issues';

    gon.relative_url_root = '/gitlab';

    expect(extractGroupOrProject()).toEqual({
      group: 'gitlab-org',
      project: undefined,
    });
  });
});

describe('parseQueryText', () => {
  it('separates the presentation layer from the query and returns an object', () => {
    const text = `---
fields: title, assignees, dueDate
display: list
---
assignee = currentUser()`;

    expect(parseQueryText(text)).toEqual({
      frontmatter: 'fields: title, assignees, dueDate\ndisplay: list',
      query: 'assignee = currentUser()',
    });
  });

  it('returns empty frontmatter if no frontmatter is present', () => {
    const text = 'assignee = currentUser()';

    expect(parseQueryText(text)).toEqual({
      frontmatter: '',
      query: 'assignee = currentUser()',
    });
  });
});

describe('parseFrontmatter', () => {
  it('parses the frontmatter and returns an object', () => {
    const frontmatter = 'fields: title, assignees, dueDate\ndisplay: list';

    expect(parseFrontmatter(frontmatter)).toEqual({
      fields: ['title', 'assignees', 'dueDate'],
      display: 'list',
    });
  });

  it('returns default fields if none are provided', () => {
    const frontmatter = 'display: list';

    expect(parseFrontmatter(frontmatter, { fields: ['title', 'assignees', 'dueDate'] })).toEqual({
      fields: ['title', 'assignees', 'dueDate'],
      display: 'list',
    });
  });
});
