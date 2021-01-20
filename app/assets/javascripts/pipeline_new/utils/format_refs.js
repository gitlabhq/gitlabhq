import { BRANCH_REF_TYPE, TAG_REF_TYPE } from '../constants';

export default (refs, type) => {
  let fullName;

  return refs.map((ref) => {
    if (type === BRANCH_REF_TYPE) {
      fullName = `refs/heads/${ref}`;
    } else if (type === TAG_REF_TYPE) {
      fullName = `refs/tags/${ref}`;
    }

    return {
      shortName: ref,
      fullName,
    };
  });
};
