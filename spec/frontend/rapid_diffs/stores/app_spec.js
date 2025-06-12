import { createTestingPinia } from '@pinia/testing';
import { useApp } from '~/rapid_diffs/stores/app';

describe('rapidDiffsApp store', () => {
  beforeEach(() => {
    createTestingPinia({ stubActions: false });
  });

  it('is visible by default', () => {
    expect(useApp().appVisible).toBe(true);
  });
});
