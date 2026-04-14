export function* getDiscussionPositions(discussion) {
  if (discussion.original_position) yield discussion.original_position;
  if (discussion.position) yield discussion.position;
  if (discussion.positions) yield* discussion.positions;
}

export function positionMatchesDiffRefs(position, diffRefs) {
  return (
    position.base_sha === diffRefs.base_sha &&
    position.head_sha === diffRefs.head_sha &&
    position.start_sha === diffRefs.start_sha
  );
}

export function positionMatchesFilePath(position, { oldPath, newPath }) {
  return position.old_path === oldPath && position.new_path === newPath;
}

export function positionMatchesLine(position, { oldPath, newPath, oldLine, newLine }) {
  return (
    positionMatchesFilePath(position, { oldPath, newPath }) &&
    position.old_line === oldLine &&
    position.new_line === newLine
  );
}

export const isFileDiscussion = (discussion) => discussion.position?.position_type === 'file';

export const isLineDiscussion = (discussion) => discussion.position?.position_type === 'text';

export const isImageDiscussion = (discussion) => discussion.position?.position_type === 'image';

export function findApplicablePosition(discussion, diffRefs) {
  for (const pos of getDiscussionPositions(discussion)) {
    if (positionMatchesDiffRefs(pos, diffRefs)) return pos;
  }
  return undefined;
}

export function discussionMatchesLinePosition(discussion, linePos, diffRefs) {
  for (const pos of getDiscussionPositions(discussion)) {
    if (positionMatchesLine(pos, linePos) && positionMatchesDiffRefs(pos, diffRefs)) return true;
  }
  return false;
}
