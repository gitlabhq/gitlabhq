import { parseQueryTextWithFrontmatter, parse } from '~/glql/core/parser';

describe('parseQueryTextWithFrontmatter', () => {
  it('separates the presentation layer from the query and returns an object', () => {
    const text = `---
fields: title, assignees, dueDate
display: list
---
assignee = currentUser()`;

    expect(parseQueryTextWithFrontmatter(text)).toEqual({
      frontmatter: 'fields: title, assignees, dueDate\ndisplay: list',
      query: 'assignee = currentUser()',
    });
  });

  it('returns empty frontmatter if no frontmatter is present', () => {
    const text = 'assignee = currentUser()';

    expect(parseQueryTextWithFrontmatter(text)).toEqual({
      frontmatter: '',
      query: 'assignee = currentUser()',
    });
  });
});

describe('parse', () => {
  beforeEach(() => {
    gon.current_username = 'root';
  });

  it('parses a simple query correctly', async () => {
    expect(await parse('assignee = currentUser()')).toMatchInlineSnapshot(`
{
  "config": {
    "display": "list",
    "fields": [
      {
        "key": "title",
        "label": "Title",
        "name": "title",
      },
    ],
  },
  "query": "query GLQL {
issues(assigneeUsernames: "root", first: 100) {
nodes {
id
iid
title
webUrl
reference
state
}
pageInfo {
startCursor
endCursor
hasNextPage
hasPreviousPage
}
}
}
",
}
`);
  });

  it('parses a query with frontmatter correctly', async () => {
    expect(
      await parse(`
---
fields: title, assignees, dueDate
display: table
---
assignee = currentUser()`),
    ).toMatchInlineSnapshot(`
{
  "config": {
    "display": "table",
    "fields": [
      {
        "key": "title",
        "label": "Title",
        "name": "title",
      },
      {
        "key": "assignees",
        "label": "Assignees",
        "name": "assignees",
      },
      {
        "key": "dueDate",
        "label": "Due date",
        "name": "dueDate",
      },
    ],
  },
  "query": "query GLQL {
issues(assigneeUsernames: "root", first: 100) {
nodes {
id
iid
title
webUrl
reference
state
assignees {
nodes {
id
avatarUrl
username
name
webUrl}
}
dueDate
}
pageInfo {
startCursor
endCursor
hasNextPage
hasPreviousPage
}
}
}
",
}
`);
  });

  it('parses a YAML based query correctly', async () => {
    expect(
      await parse(`
fields: title, assignees, dueDate
display: table
limit: 20
query: assignee = currentUser()
`),
    ).toMatchInlineSnapshot(`
{
  "config": {
    "display": "table",
    "fields": [
      {
        "key": "title",
        "label": "Title",
        "name": "title",
      },
      {
        "key": "assignees",
        "label": "Assignees",
        "name": "assignees",
      },
      {
        "key": "dueDate",
        "label": "Due date",
        "name": "dueDate",
      },
    ],
    "limit": 20,
  },
  "query": "query GLQL {
issues(assigneeUsernames: "root", first: 20) {
nodes {
id
iid
title
webUrl
reference
state
assignees {
nodes {
id
avatarUrl
username
name
webUrl}
}
dueDate
}
pageInfo {
startCursor
endCursor
hasNextPage
hasPreviousPage
}
}
}
",
}
`);
  });
});
