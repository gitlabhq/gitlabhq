export const mockImportFailures = [
  {
    type: 'pull_request',
    title: 'Add one cool feature',
    provider_url: 'https://github.com/USER/REPO/pull/2',
    details: {
      exception_class: 'ActiveRecord::RecordInvalid',
      exception_message: 'Record invalid',
      source: 'Gitlab::GithubImport::Importer::PullRequestImporter',
      external_identifiers: {
        iid: 2,
        issuable_type: 'MergeRequest',
        object_type: 'pull_request',
      },
    },
  },
  {
    type: 'pull_request',
    title: 'Add another awesome feature',
    provider_url: 'https://github.com/USER/REPO/pull/3',
    details: {
      exception_class: 'ActiveRecord::RecordInvalid',
      exception_message: 'Record invalid',
      source: 'Gitlab::GithubImport::Importer::PullRequestImporter',
      external_identifiers: {
        iid: 3,
        issuable_type: 'MergeRequest',
        object_type: 'pull_request',
      },
    },
  },
  {
    type: 'lfs_object',
    title: '3a9257fae9e86faee27d7208cb55e086f18e6f29f48c430bfbc26d42eb',
    provider_url: null,
    details: {
      exception_class: 'NameError',
      exception_message: 'some message',
      source: 'Gitlab::GithubImport::Importer::LfsObjectImporter',
      external_identifiers: {
        oid: '3a9257fae9e86faee27d7208cb55e086f18e6f29f48c430bfbc26d42eb',
        size: 2473979,
      },
    },
  },
];

export const mockHeaders = {
  'x-page': 1,
  'x-per-page': 20,
  'x-total': 3,
  'x-total-pages': 1,
};
