import { __ } from '~/locale';
import { BRANCH_REF_TYPE, TAG_REF_TYPE } from '../constants';

function convertToListBoxItems(items) {
  return items.map(({ shortName, fullName }) => ({ text: shortName, value: fullName }));
}

export function formatToShortName(ref) {
  return ref.replace(/^refs\/(tags|heads)\//, '');
}

export function formatRefs(refs, type) {
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
}

export const formatListBoxItems = (branches, tags) => {
  const finalResults = [];

  if (branches.length > 0) {
    finalResults.push({
      text: __('Branches'),
      options: convertToListBoxItems(formatRefs(branches, BRANCH_REF_TYPE)),
    });
  }

  if (tags.length > 0) {
    finalResults.push({
      text: __('Tags'),
      options: convertToListBoxItems(formatRefs(tags, TAG_REF_TYPE)),
    });
  }

  return finalResults;
};

export const searchByFullNameInListboxOptions = (fullName, listBox) => {
  const optionsToSearch =
    listBox.length > 1 ? listBox[0].options.concat(listBox[1].options) : listBox[0]?.options;

  const foundOption = optionsToSearch.find(({ value }) => value === fullName);

  return {
    shortName: foundOption.text,
    fullName: foundOption.value,
  };
};
