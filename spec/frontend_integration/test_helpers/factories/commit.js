import { withValues } from '../utils/obj';
import { getCommit } from '../fixtures';
import { createCommitId } from './commit_id';

// eslint-disable-next-line import/prefer-default-export
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
