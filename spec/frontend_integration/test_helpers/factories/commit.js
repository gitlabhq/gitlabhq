import { getCommit } from '../fixtures';
import { withValues } from '../utils/obj';
import { createCommitId } from './commit_id';

export const createNewCommit = ({ id = createCommitId(), message }, orig = getCommit()) => {
  return withValues(orig, {
    id,
    short_id: id.substr(0, 8),
    message,
    title: message,
    web_url: orig.web_url.replace(orig.id, id),
    parent_ids: [orig.id],
  });
};
