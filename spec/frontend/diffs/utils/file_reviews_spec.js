import { useLocalStorageSpy } from 'helpers/local_storage_helper';

import {
  getReviewsForMergeRequest,
  setReviewsForMergeRequest,
  isFileReviewed,
  markFileReview,
  reviewStatuses,
  reviewable,
} from '~/diffs/utils/file_reviews';

function getDefaultReviews() {
  return {
    abc: ['123', 'hash:xyz', '098', 'hash:uvw'],
  };
}

describe('File Review(s) utilities', () => {
  const mrPath = 'my/fake/mr/42';
  const storageKey = `${mrPath}-file-reviews`;
  const file = { id: '123', file_hash: 'xyz', file_identifier_hash: 'abc' };
  const storedValue = JSON.stringify(getDefaultReviews());
  let reviews;

  useLocalStorageSpy();

  beforeEach(() => {
    reviews = getDefaultReviews();
    localStorage.clear();
  });

  describe('isFileReviewed', () => {
    it.each`
      description                            | diffFile                      | fileReviews
      ${'the file does not have an `id`'}    | ${{ ...file, id: undefined }} | ${getDefaultReviews()}
      ${'there are no reviews for the file'} | ${file}                       | ${{ ...getDefaultReviews(), abc: undefined }}
    `('returns `false` if $description', ({ diffFile, fileReviews }) => {
      expect(isFileReviewed(fileReviews, diffFile)).toBe(false);
    });

    it("returns `true` for a file if it's available in the provided reviews", () => {
      expect(isFileReviewed(reviews, file)).toBe(true);
    });
  });

  describe('reviewStatuses', () => {
    const file1 = { id: '123', hash: 'xyz', file_identifier_hash: 'abc' };
    const file2 = { id: '098', hash: 'uvw', file_identifier_hash: 'abc' };

    it.each`
      mrReviews                         | files             | fileReviews
      ${{}}                             | ${[file1, file2]} | ${{ 123: false, '098': false }}
      ${{ abc: ['123', 'hash:xyz'] }}   | ${[file1, file2]} | ${{ 123: true, '098': false }}
      ${{ abc: ['098', 'hash:uvw'] }}   | ${[file1, file2]} | ${{ 123: false, '098': true }}
      ${{ def: ['123'] }}               | ${[file1, file2]} | ${{ 123: false, '098': false }}
      ${{ abc: ['123'], def: ['098'] }} | ${[]}             | ${{}}
    `(
      'returns $fileReviews based on the diff files in state and the existing reviews $reviews',
      ({ mrReviews, files, fileReviews }) => {
        expect(reviewStatuses(files, mrReviews)).toStrictEqual(fileReviews);
      },
    );
  });

  describe('getReviewsForMergeRequest', () => {
    it('fetches the appropriate stored reviews from localStorage', () => {
      getReviewsForMergeRequest(mrPath);

      expect(localStorage.getItem).toHaveBeenCalledTimes(1);
      expect(localStorage.getItem).toHaveBeenCalledWith(storageKey);
    });

    it('returns an empty object if there have never been stored reviews for this MR', () => {
      expect(getReviewsForMergeRequest(mrPath)).toStrictEqual({});
    });

    it.each`
      data
      ${'+++'}
      ${'{ lookinGood: "yeah!", missingClosingBrace: "yeah :(" '}
    `(
      "returns an empty object if the stored reviews are corrupted/aren't parseable as JSON (like: $data)",
      ({ data }) => {
        localStorage.getItem.mockReturnValueOnce(data);

        expect(getReviewsForMergeRequest(mrPath)).toStrictEqual({});
      },
    );

    it('fetches the reviews for the MR if they exist', () => {
      localStorage.setItem(storageKey, storedValue);

      expect(getReviewsForMergeRequest(mrPath)).toStrictEqual(reviews);
    });
  });

  describe('setReviewsForMergeRequest', () => {
    it('sets the new value to localStorage', () => {
      setReviewsForMergeRequest(mrPath, reviews);

      expect(localStorage.setItem).toHaveBeenCalledTimes(1);
      expect(localStorage.setItem).toHaveBeenCalledWith(storageKey, storedValue);
    });

    it('returns the new value for chainability', () => {
      expect(setReviewsForMergeRequest(mrPath, reviews)).toStrictEqual(reviews);
    });
  });

  describe('reviewable', () => {
    it.each`
      response | diffFile                                        | description
      ${true}  | ${file}                                         | ${'has an `.id` and a `.file_identifier_hash`'}
      ${false} | ${{ file_identifier_hash: 'abc' }}              | ${'does not have an `.id`'}
      ${false} | ${{ ...file, id: undefined }}                   | ${'has an undefined `.id`'}
      ${false} | ${{ ...file, id: null }}                        | ${'has a null `.id`'}
      ${false} | ${{ ...file, id: 0 }}                           | ${'has an `.id` set to 0'}
      ${false} | ${{ ...file, id: false }}                       | ${'has an `.id` set to false'}
      ${false} | ${{ id: '123' }}                                | ${'does not have a `.file_identifier_hash`'}
      ${false} | ${{ ...file, file_identifier_hash: undefined }} | ${'has an undefined `.file_identifier_hash`'}
      ${false} | ${{ ...file, file_identifier_hash: null }}      | ${'has a null `.file_identifier_hash`'}
      ${false} | ${{ ...file, file_identifier_hash: 0 }}         | ${'has a `.file_identifier_hash` set to 0'}
      ${false} | ${{ ...file, file_identifier_hash: false }}     | ${'has a `.file_identifier_hash` set to false'}
    `('returns `$response` when the file $description`', ({ response, diffFile }) => {
      expect(reviewable(diffFile)).toBe(response);
    });
  });

  describe('markFileReview', () => {
    it("adds a review when there's nothing that already exists", () => {
      expect(markFileReview(null, file)).toStrictEqual({ abc: ['123', 'hash:xyz'] });
    });

    it("overwrites an existing review if it's for the same file (identifier hash)", () => {
      expect(markFileReview(reviews, file)).toStrictEqual(getDefaultReviews());
    });

    it('removes a review from the list when `reviewed` is `false`', () => {
      expect(markFileReview(reviews, file, false)).toStrictEqual({ abc: ['098', 'hash:uvw'] });
    });

    it('adds a new review if the file ID is new', () => {
      const updatedFile = { ...file, id: '098', file_hash: 'uvw' };
      const allReviews = markFileReview({ abc: ['123', 'hash:xyz'] }, updatedFile);

      expect(allReviews).toStrictEqual(getDefaultReviews());
      expect(allReviews.abc).toStrictEqual(['123', 'hash:xyz', '098', 'hash:uvw']);
    });

    it.each`
      description                            | diffFile
      ${'missing an `.id`'}                  | ${{ file_identifier_hash: 'abc' }}
      ${'missing a `.file_identifier_hash`'} | ${{ id: '123' }}
    `("doesn't modify the reviews if the file is $description", ({ diffFile }) => {
      expect(markFileReview(reviews, diffFile)).toStrictEqual(getDefaultReviews());
    });

    it('removes the file key if there are no more reviews for it', () => {
      let updated = markFileReview(reviews, file, false);

      updated = markFileReview(updated, { ...file, id: '098', file_hash: 'uvw' }, false);

      expect(updated).toStrictEqual({});
    });
  });
});
