// eslint-disable-next-line import/prefer-default-export
export function normalizeData(data, path, extra = () => {}) {
  return data.map(d => ({
    sha: d.commit.id,
    message: d.commit.message,
    committedDate: d.commit.committed_date,
    commitPath: d.commit_path,
    fileName: d.file_name,
    filePath: `${path}/${d.file_name}`,
    type: d.type,
    __typename: 'LogTreeCommit',
    ...extra(d),
  }));
}
