import { autocompleteDataSources, markdownPreviewPath, workItemPath } from '~/work_items/utils';

describe('autocompleteDataSources', () => {
  beforeEach(() => {
    gon.relative_url_root = '/foobar';
  });

  it('returns corrrect data sources', () => {
    expect(autocompleteDataSources('project/group', '2')).toMatchObject({
      commands: '/foobar/project/group/-/autocomplete_sources/commands?type=WorkItem&type_id=2',
      labels: '/foobar/project/group/-/autocomplete_sources/labels?type=WorkItem&type_id=2',
      members: '/foobar/project/group/-/autocomplete_sources/members?type=WorkItem&type_id=2',
    });
  });
});

describe('markdownPreviewPath', () => {
  beforeEach(() => {
    gon.relative_url_root = '/foobar';
  });

  it('returns corrrect data sources', () => {
    expect(markdownPreviewPath('project/group', '2')).toEqual(
      '/foobar/project/group/preview_markdown?target_type=WorkItem&target_id=2',
    );
  });
});

describe('workItemPath', () => {
  it('returns corrrect data sources', () => {
    expect(workItemPath('project/group', '2')).toEqual('/project/group/-/work_items/2');
  });

  it('returns corrrect data sources with relative url root', () => {
    gon.relative_url_root = '/foobar';
    expect(workItemPath('project/group', '2')).toEqual('/foobar/project/group/-/work_items/2');
  });
});
