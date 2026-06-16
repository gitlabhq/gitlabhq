import { watch } from 'vue';
import { pinia } from '~/pinia/instance';
import { __, n__ } from '~/locale';
import { EXPANDED_LINES, MOUNTED } from '~/rapid_diffs/adapter_events';
import { useTestCoverage } from '~/rapid_diffs/stores/test_coverage';

/* eslint-disable no-param-reassign */
function applyCoverage(slot, hits) {
  if (hits === 0) {
    slot.dataset.coverage = 'miss';
    slot.title = __('No test coverage');
  } else if (hits > 0) {
    slot.dataset.coverage = 'hit';
    slot.title = n__('Test coverage: %d hit', 'Test coverage: %d hits', hits);
  }
}
/* eslint-enable no-param-reassign */

function decorateCoverage(diffElement, lineHits) {
  if (!lineHits) return;

  diffElement.querySelectorAll('[data-line-coverage]:not([data-coverage])').forEach((slot) => {
    const hits = lineHits[slot.dataset.lineCoverage];
    if (typeof hits === 'number') applyCoverage(slot, hits);
  });
}

export const lineCoverageAdapter = {
  [MOUNTED](addCleanup) {
    const { diffElement } = this;
    const { newPath } = this.data;
    if (!newPath) return;

    const store = useTestCoverage(pinia);
    const stopWatch = watch(
      () => store.lineHitsForFile(newPath),
      (lineHits) => decorateCoverage(diffElement, lineHits),
      { immediate: true },
    );
    addCleanup(stopWatch);
  },
  [EXPANDED_LINES]() {
    const { newPath } = this.data;
    if (!newPath) return;
    const store = useTestCoverage(pinia);
    decorateCoverage(this.diffElement, store.lineHitsForFile(newPath));
  },
};
