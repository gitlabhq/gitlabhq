const path = 'some/path.js';
const blamePath = 'some/blame/path.js';

export const LANGUAGE_MOCK = 'docker';

export const BLOB_DATA_MOCK = { language: LANGUAGE_MOCK, path, blamePath };

export const CHUNK_1 = {
  isHighlighted: true,
  rawContent: 'chunk 1 raw',
  highlightedContent: 'chunk 1 highlighted',
  totalLines: 70,
  startingFrom: 0,
  blamePath,
};

export const CHUNK_2 = {
  isHighlighted: false,
  rawContent: 'chunk 2 raw',
  highlightedContent: 'chunk 2 highlighted',
  totalLines: 40,
  startingFrom: 70,
  blamePath,
};

export const CHUNK_3 = {
  isHighlighted: false,
  rawContent: 'chunk 3 raw',
  highlightedContent: 'chunk 3 highlighted',
  totalLines: 40,
  startingFrom: 110,
  blamePath,
};

export const SOURCE_CODE_CONTENT_MOCK = `    
<div class="file-holder">
  <div class="blob-viewer">
    <div class="content">
      <div>
        <div id="L1">1</div>
        <div id="L2">2</div>
        <div id="L3">3</div>
      </div>

      <div>
        <div id="LC1">Content 1</div>
        <div id="LC2">Content 2</div>
        <div id="LC3">Content 3</div>
      </div>
    </div>
  </div>
</div>`;

const COMMIT_DATA_MOCK = { projectBlameLink: 'project/blame/link' };

export const BLAME_DATA_MOCK = [
  {
    lineno: 1,
    commit: { author: 'Peter', sha: 'abc' },
    index: 0,
    blameOffset: '0px',
    commitData: COMMIT_DATA_MOCK,
  },
  { lineno: 2, commit: { author: 'Sarah', sha: 'def' }, index: 1, blameOffset: '1px' },
  { lineno: 3, commit: { author: 'Peter', sha: 'ghi' }, index: 2, blameOffset: '2px' },
];

export const BLAME_DATA_QUERY_RESPONSE_MOCK = {
  data: {
    project: {
      id: 'gid://gitlab/Project/278964',
      __typename: 'Project',
      repository: {
        __typename: 'Repository',
        blobs: {
          __typename: 'BlobConnection',
          nodes: [
            {
              id: 'gid://gitlab/Blob/f0c77e4b621df72719ce2b500ea6228559f6bc09',
              blame: {
                firstLine: '1',
                groups: [
                  {
                    lineno: 1,
                    span: 3,
                    commit: {
                      id: 'gid://gitlab/CommitPresenter/13b0aca4142d1d55931577f69289a792f216f805',
                      titleHtml: 'Upload New File',
                      message: 'Upload New File',
                      authoredDate: '2022-10-31T10:38:30+00:00',
                      authorName: 'Peter',
                      authorGravatar: 'path/to/gravatar',
                      webPath: '/commit/1234',
                      author: {},
                      sha: '13b0aca4142d1d55931577f69289a792f216f805',
                    },
                    commitData: COMMIT_DATA_MOCK,
                  },
                ],
              },
            },
          ],
        },
      },
    },
  },
};
