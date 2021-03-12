function getFileReviewsKey(mrPath) {
  return `${mrPath}-file-reviews`;
}

export function isFileReviewed(reviews, file) {
  const fileReviews = reviews[file.file_identifier_hash];

  return file?.id && fileReviews?.length ? new Set(fileReviews).has(file.id) : false;
}

export function reviewStatuses(files, reviews) {
  return files.reduce((flat, file) => {
    return {
      ...flat,
      [file.id]: isFileReviewed(reviews, file),
    };
  }, {});
}

export function getReviewsForMergeRequest(mrPath) {
  const reviewsForMr = localStorage.getItem(getFileReviewsKey(mrPath));
  let reviews = {};

  if (reviewsForMr) {
    try {
      reviews = JSON.parse(reviewsForMr);
    } catch (err) {
      reviews = {};
    }
  }

  return reviews;
}

export function setReviewsForMergeRequest(mrPath, reviews) {
  localStorage.setItem(getFileReviewsKey(mrPath), JSON.stringify(reviews));

  return reviews;
}

export function reviewable(file) {
  return Boolean(file.id) && Boolean(file.file_identifier_hash);
}

export function markFileReview(reviews, file, reviewed = true) {
  const usableReviews = { ...(reviews || {}) };
  const updatedReviews = usableReviews;
  let fileReviews;

  if (reviewable(file)) {
    fileReviews = new Set(usableReviews[file.file_identifier_hash] || []);

    if (reviewed) {
      fileReviews.add(file.id);
    } else {
      fileReviews.delete(file.id);
    }

    updatedReviews[file.file_identifier_hash] = Array.from(fileReviews);

    if (updatedReviews[file.file_identifier_hash].length === 0) {
      delete updatedReviews[file.file_identifier_hash];
    }
  }

  return updatedReviews;
}
