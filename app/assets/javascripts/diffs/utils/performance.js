import { performanceMarkAndMeasure } from '~/performance/utils';
import {
  MR_DIFFS_MARK_FILE_TREE_START,
  MR_DIFFS_MARK_FILE_TREE_END,
  MR_DIFFS_MARK_DIFF_FILES_START,
  MR_DIFFS_MARK_FIRST_DIFF_FILE_SHOWN,
  MR_DIFFS_MARK_DIFF_FILES_END,
  MR_DIFFS_MEASURE_FILE_TREE_DONE,
  MR_DIFFS_MEASURE_DIFF_FILES_DONE,
} from '~/performance/constants';

import {
  EVT_PERF_MARK_FILE_TREE_START,
  EVT_PERF_MARK_FILE_TREE_END,
  EVT_PERF_MARK_DIFF_FILES_START,
  EVT_PERF_MARK_FIRST_DIFF_FILE_SHOWN,
  EVT_PERF_MARK_DIFF_FILES_END,
} from '../constants';
import eventHub from '../event_hub';

function treeStart() {
  performanceMarkAndMeasure({
    mark: MR_DIFFS_MARK_FILE_TREE_START,
  });
}

function treeEnd() {
  performanceMarkAndMeasure({
    mark: MR_DIFFS_MARK_FILE_TREE_END,
    measures: [
      {
        name: MR_DIFFS_MEASURE_FILE_TREE_DONE,
        start: MR_DIFFS_MARK_FILE_TREE_START,
        end: MR_DIFFS_MARK_FILE_TREE_END,
      },
    ],
  });
}

function filesStart() {
  performanceMarkAndMeasure({
    mark: MR_DIFFS_MARK_DIFF_FILES_START,
  });
}

function filesEnd() {
  performanceMarkAndMeasure({
    mark: MR_DIFFS_MARK_DIFF_FILES_END,
    measures: [
      {
        name: MR_DIFFS_MEASURE_DIFF_FILES_DONE,
        start: MR_DIFFS_MARK_DIFF_FILES_START,
        end: MR_DIFFS_MARK_DIFF_FILES_END,
      },
    ],
  });
}

function firstFile() {
  performanceMarkAndMeasure({
    mark: MR_DIFFS_MARK_FIRST_DIFF_FILE_SHOWN,
  });
}

export const diffsApp = {
  instrument() {
    eventHub.$on(EVT_PERF_MARK_FILE_TREE_START, treeStart);
    eventHub.$on(EVT_PERF_MARK_FILE_TREE_END, treeEnd);
    eventHub.$on(EVT_PERF_MARK_DIFF_FILES_START, filesStart);
    eventHub.$on(EVT_PERF_MARK_DIFF_FILES_END, filesEnd);
    eventHub.$on(EVT_PERF_MARK_FIRST_DIFF_FILE_SHOWN, firstFile);
  },
  deinstrument() {
    eventHub.$off(EVT_PERF_MARK_FIRST_DIFF_FILE_SHOWN, firstFile);
    eventHub.$off(EVT_PERF_MARK_DIFF_FILES_END, filesEnd);
    eventHub.$off(EVT_PERF_MARK_DIFF_FILES_START, filesStart);
    eventHub.$off(EVT_PERF_MARK_FILE_TREE_END, treeEnd);
    eventHub.$off(EVT_PERF_MARK_FILE_TREE_START, treeStart);
  },
};
