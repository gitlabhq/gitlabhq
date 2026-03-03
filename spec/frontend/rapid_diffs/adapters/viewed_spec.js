import { createTestingPinia } from '@pinia/testing';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { viewedAdapter } from '~/rapid_diffs/adapters/viewed';
import { toggleFileAdapter } from '~/rapid_diffs/adapters/toggle_file';
import { useCodeReview } from '~/diffs/stores/code_review';

const CODE_REVIEW_ID = 'abc123def456';
const MR_PATH = '/namespace/project/-/merge_requests/1';
const STORAGE_KEY = `code-review-${MR_PATH}`;

if (!window.CSS) {
  window.CSS = {
    escape: (val) => val.replace(/[!"#$%&'()*+,./:;<=>?@[\\\]^`{|}~]/g, '\\$&'),
  };
}

describe('Viewed Adapter', () => {
  function get(element) {
    const elements = {
      file: () => document.querySelector('diff-file'),
      checkbox: () => get('file').querySelector('[data-viewed-checkbox]'),
      body: () => get('file').querySelector('[data-file-body]'),
    };

    return elements[element]?.();
  }

  const delegatedClick = (element) => {
    let event;
    element.addEventListener(
      'click',
      (e) => {
        event = e;
      },
      { once: true },
    );
    element.click();
    get('file').onClick(event);
  };

  const mount = (reviewedIds = [], { codeReviewEnabled = true } = {}) => {
    if (reviewedIds.length) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(reviewedIds));
    }

    const store = useCodeReview();

    store.setMrPath(MR_PATH);
    store.restoreFromAutosave();
    store.restoreFromLegacyMrReviews();

    const viewer = 'any';
    document.body.innerHTML = `
      <diff-file data-file-data='${JSON.stringify({ viewer, codeReviewId: CODE_REVIEW_ID })}' data-code-review-id="${CODE_REVIEW_ID}">
        <div class="rd-diff-file">
          <div class="rd-diff-file-header">
            <label class="rd-diff-file-viewed">
              <input type="checkbox" data-click="toggleViewed" data-viewed-checkbox disabled>
              Viewed
            </label>
          </div>
          <details open data-file-body=""><summary></summary><div>body</div></details>
        </div>
      </diff-file>
    `;
    get('file').mount({
      adapterConfig: { [viewer]: [toggleFileAdapter, viewedAdapter] },
      appData: { mrPath: MR_PATH, codeReviewEnabled },
      unobserve: jest.fn(),
    });
  };

  beforeAll(() => {
    if (!customElements.get('diff-file')) {
      customElements.define('diff-file', DiffFile);
    }
  });

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    localStorage.clear();
    document.head.innerHTML = '';
  });

  afterEach(() => {
    document.body.innerHTML = '';
    document.head.innerHTML = '';
    localStorage.clear();
  });

  describe('MOUNTED', () => {
    it('does not enable the checkbox when code review is not enabled', () => {
      mount([], { codeReviewEnabled: false });

      expect(get('checkbox').disabled).toBe(true);
    });

    it('enables the checkbox', () => {
      mount([]);

      expect(get('checkbox').disabled).toBe(false);
    });

    it('sets checkbox to unchecked when file is not viewed', () => {
      mount([]);

      expect(get('checkbox').checked).toBe(false);
      expect(Object.hasOwn(get('file').diffElement.dataset, 'viewed')).toBe(false);
    });

    it('sets checkbox to checked when file is viewed', () => {
      mount([CODE_REVIEW_ID]);

      expect(get('checkbox').checked).toBe(true);
      expect(Object.hasOwn(get('file').diffElement.dataset, 'viewed')).toBe(true);
    });

    it('sets data-collapsed when file is viewed', () => {
      mount([CODE_REVIEW_ID]);

      expect(get('file').diffElement.dataset.collapsed).toBe('true');
    });

    it('removes FOUC style tag on mount', () => {
      // Simulate FOUC script adding style tag before mount
      const style = document.createElement('style');
      style.dataset.viewedFileStyle = CODE_REVIEW_ID;
      document.head.appendChild(style);

      mount([CODE_REVIEW_ID]);

      expect(
        document.querySelector(`style[data-viewed-file-style="${CODE_REVIEW_ID}"]`),
      ).toBeNull();
    });
  });

  describe('toggleViewed click', () => {
    it('marks file as viewed and collapses with scroll when checkbox is checked', () => {
      mount([]);
      const scrollIntoViewSpy = jest.spyOn(get('file').diffElement, 'scrollIntoView');

      delegatedClick(get('checkbox'));

      expect(JSON.parse(localStorage.getItem(STORAGE_KEY))).toContain(CODE_REVIEW_ID);
      expect(Object.hasOwn(get('file').diffElement.dataset, 'viewed')).toBe(true);
      expect(get('body').open).toBe(false);
      expect(scrollIntoViewSpy).toHaveBeenCalledWith({
        block: 'nearest',
        inline: 'nearest',
        behavior: 'instant',
      });
    });

    it('marks file as not viewed and expands when checkbox is unchecked', () => {
      mount([CODE_REVIEW_ID]);

      delegatedClick(get('checkbox'));

      expect(localStorage.getItem(STORAGE_KEY)).toBeNull();
      expect(Object.hasOwn(get('file').diffElement.dataset, 'viewed')).toBe(false);
      expect(get('body').open).toBe(true);
    });

    it('does not add style tags when toggling viewed state', () => {
      mount([]);

      delegatedClick(get('checkbox'));

      expect(
        document.querySelector(`style[data-viewed-file-style="${CODE_REVIEW_ID}"]`),
      ).toBeNull();
    });
  });
});
