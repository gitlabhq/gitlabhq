import {
  getGroupOrProjectFromUrl,
  getGroupOrProjectFromPageData,
  toSentenceCase,
  relativeNamespace,
  wrapQueryInGlqlBlock,
  copyQuerySource,
} from '~/glql/utils/common';
import { copyToClipboard } from '~/lib/utils/copy_to_clipboard';

jest.mock('~/lib/utils/copy_to_clipboard');

describe('getGroupOrProjectFromUrl', () => {
  afterEach(() => {
    delete gon.relative_url_root;
  });

  describe.each`
    path                                         | relativeUrlRoot | group                       | project
    ${'/gitlab-org/gitlab-test/-/issues'}        | ${''}           | ${undefined}                | ${'gitlab-org/gitlab-test'}
    ${'/groups/gitlab-org/-/issues'}             | ${''}           | ${'gitlab-org'}             | ${undefined}
    ${'/groups/gitlab-org/gitlab-test/-/issues'} | ${''}           | ${'gitlab-org/gitlab-test'} | ${undefined}
    ${'/gitlab-org/gitlab-test/-/issues'}        | ${'/gitlab'}    | ${undefined}                | ${'gitlab-org/gitlab-test'}
    ${'/groups/gitlab-org/-/issues'}             | ${'/gitlab'}    | ${'gitlab-org'}             | ${undefined}
    ${'/groups/gitlab-org/gitlab-test/-/issues'} | ${'/gitlab'}    | ${'gitlab-org/gitlab-test'} | ${undefined}
  `('for $relativeUrlRoot$path', ({ path, relativeUrlRoot, group, project }) => {
    const fullPath = `${relativeUrlRoot}${path}`;

    beforeEach(() => {
      gon.relative_url_root = relativeUrlRoot;
    });

    it('returns the correct group or project from an absolute URL', () => {
      expect(getGroupOrProjectFromUrl(`https://gitlab.com${fullPath}`)).toEqual({ group, project });
    });

    it('returns the correct group or project from a relative path', () => {
      expect(getGroupOrProjectFromUrl(fullPath)).toEqual({ group, project });
    });
  });
});

describe('getGroupOrProjectFromPageData', () => {
  afterEach(() => {
    delete document.body.dataset.projectFullPath;
    delete document.body.dataset.groupFullPath;
  });

  it('returns the project of the current page', () => {
    document.body.dataset.projectFullPath = 'gitlab-org/gitlab-test';

    expect(getGroupOrProjectFromPageData()).toEqual({ project: 'gitlab-org/gitlab-test' });
  });

  it('returns the group of the current page', () => {
    document.body.dataset.groupFullPath = 'gitlab-org';

    expect(getGroupOrProjectFromPageData()).toEqual({ group: 'gitlab-org' });
  });

  it('returns the project when the page is scoped to a project within a group', () => {
    document.body.dataset.projectFullPath = 'gitlab-org/gitlab-test';
    document.body.dataset.groupFullPath = 'gitlab-org';

    expect(getGroupOrProjectFromPageData()).toEqual({ project: 'gitlab-org/gitlab-test' });
  });

  it('returns an empty object when the page is not scoped to a group or project', () => {
    expect(getGroupOrProjectFromPageData()).toEqual({});
  });
});

describe('toSentenceCase', () => {
  it.each`
    str                     | expected
    ${'title'}              | ${'Title'}
    ${'camelCasedExample'}  | ${'Camel cased example'}
    ${'snake_case_example'} | ${'Snake case example'}
    ${'id'}                 | ${'ID'}
    ${'iid'}                | ${'IID'}
  `('returns $expected for $str', ({ str, expected }) => {
    expect(toSentenceCase(str)).toBe(expected);
  });
});

describe('relativeNamespace', () => {
  it.each`
    source                       | target                       | expected
    ${'gitlab-org/gitlab-shell'} | ${'gitlab-org/gitlab-test'}  | ${'gitlab-test'}
    ${'gitlab-org/gitlab-shell'} | ${'gitlab-org/gitlab-shell'} | ${''}
    ${'gitlab-org/gitlab-shell'} | ${'gitlab-org'}              | ${'gitlab-org'}
    ${'group/subgroup/project'}  | ${'group/subgroup/project'}  | ${''}
    ${'group/subgroup/project'}  | ${'group/subgroup/project2'} | ${'project2'}
    ${'group/subgroup/project'}  | ${'group/subgroup2/project'} | ${'subgroup2/project'}
    ${'group/subgroup/project'}  | ${'group/subgroup'}          | ${'group/subgroup'}
    ${'group/subgroup/project'}  | ${'group'}                   | ${'group'}
    ${''}                        | ${'group/subgroup/project'}  | ${'group/subgroup/project'}
  `('returns $expected for $source and $target', ({ source, target, expected }) => {
    expect(relativeNamespace(source, target)).toBe(expected);
  });
});

describe('GLQL query source', () => {
  const query = 'type = Issue AND state = opened';
  const wrappedQuery = `\`\`\`glql\n${query}\n\`\`\``;

  describe('wrapQueryInGlqlBlock', () => {
    it('wraps the query in a fenced glql block', () => {
      expect(wrapQueryInGlqlBlock(query)).toBe(wrappedQuery);
    });
  });

  describe('copyQuerySource', () => {
    it('copies the wrapped query to the clipboard', () => {
      copyQuerySource(query);

      expect(copyToClipboard).toHaveBeenCalledWith(wrappedQuery, document.body);
    });

    it('copies from the given container', () => {
      const container = document.createElement('div');

      copyQuerySource(query, container);

      expect(copyToClipboard).toHaveBeenCalledWith(wrappedQuery, container);
    });
  });
});
