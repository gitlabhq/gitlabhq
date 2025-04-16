function cacheId({ issuableId, listId } = {}) {
  return `MergeRequest/${issuableId}/${listId}`;
}

export function setReviewersForList({ issuableId, listId, reviewers = [] } = {}) {
  const id = cacheId({ issuableId, listId });

  window.sessionStorage.setItem(id, JSON.stringify(reviewers, null, 0));
}

export function getReviewersForList({ issuableId, listId } = {}) {
  const id = cacheId({ issuableId, listId });
  const list = window.sessionStorage.getItem(id);

  return list ? JSON.parse(list) : [];
}

export function suggestedPosition({ username, list = [] } = {}) {
  return list.indexOf(username) + 1; // 1-index, so that "0" means they weren't in the list
}
