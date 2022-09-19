import { joinPaths } from '~/lib/utils/url_utility';

export function normalizeData(data, path, extra = () => {}) {
  return data.map((d) => ({
    sha: d.commit.id,
    message: d.commit.message,
    titleHtml: d.commit_title_html,
    committedDate: d.commit.committed_date,
    commitPath: d.commit_path,
    fileName: d.file_name,
    filePath: joinPaths(path, d.file_name),
    __typename: 'LogTreeCommit',
    ...extra(d),
  }));
}
