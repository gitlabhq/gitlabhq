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

export const SOURCE_CODE_CONTENT_MOCK = `    
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
</div>`;

export const BLAME_DATA_MOCK = [
  { lineno: 1, commit: { author: 'Peter' }, index: 0 },
  { lineno: 2, commit: { author: 'Sarah' }, index: 1 },
  { lineno: 3, commit: { author: 'Peter' }, index: 2 },
];
