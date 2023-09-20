import { uniqueId } from 'lodash';
import { SNIPPET_MARK_BLOBS_CONTENT, SNIPPET_MEASURE_BLOBS_CONTENT } from '~/performance/constants';
import { performanceMarkAndMeasure } from '~/performance/utils';
import { VISIBILITY_LEVELS_INTEGER_TO_STRING } from '~/visibility_level/constants';
import {
  SNIPPET_BLOB_ACTION_CREATE,
  SNIPPET_BLOB_ACTION_UPDATE,
  SNIPPET_BLOB_ACTION_MOVE,
  SNIPPET_BLOB_ACTION_DELETE,
  SNIPPET_VISIBILITY,
} from '../constants';

const createLocalId = () => uniqueId('blob_local_');

export const decorateBlob = (blob) => ({
  ...blob,
  id: createLocalId(),
  isLoaded: false,
  content: '',
});

export const createBlob = () => ({
  id: createLocalId(),
  content: '',
  path: '',
  isLoaded: true,
});

const diff = ({ content, path }, origBlob) => {
  if (!origBlob) {
    return {
      action: SNIPPET_BLOB_ACTION_CREATE,
      previousPath: path,
      content,
      filePath: path,
    };
  }
  if (origBlob.path !== path || origBlob.content !== content) {
    return {
      action: origBlob.path === path ? SNIPPET_BLOB_ACTION_UPDATE : SNIPPET_BLOB_ACTION_MOVE,
      previousPath: origBlob.path,
      content,
      filePath: path,
    };
  }

  return null;
};

/**
 * This function returns an array of diff actions (to be sent to the BE) based on the current vs. original blobs
 *
 * @param {Object} blobs
 * @param {Object} origBlobs
 */
export const diffAll = (blobs, origBlobs) => {
  const deletedEntries = Object.values(origBlobs)
    .filter((x) => !blobs[x.id])
    .map(({ path, content }) => ({
      action: SNIPPET_BLOB_ACTION_DELETE,
      previousPath: path,
      filePath: path,
      content,
    }));

  const newEntries = Object.values(blobs)
    .map((blob) => diff(blob, origBlobs[blob.id]))
    .filter((x) => x);

  return [...deletedEntries, ...newEntries];
};

export const defaultSnippetVisibilityLevels = (arr) => {
  if (Array.isArray(arr)) {
    return arr.map((l) => {
      const translatedLevel = VISIBILITY_LEVELS_INTEGER_TO_STRING[l];
      return {
        value: translatedLevel,
        ...SNIPPET_VISIBILITY[translatedLevel],
      };
    });
  }
  return [];
};

export const markBlobPerformance = () => {
  performanceMarkAndMeasure({
    mark: SNIPPET_MARK_BLOBS_CONTENT,
    measures: [
      {
        name: SNIPPET_MEASURE_BLOBS_CONTENT,
        start: undefined,
        end: SNIPPET_MARK_BLOBS_CONTENT,
      },
    ],
  });
};
