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
