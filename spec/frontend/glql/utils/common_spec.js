import { extractGroupOrProject, toSentenceCase, relativeNamespace } from '~/glql/utils/common';
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
