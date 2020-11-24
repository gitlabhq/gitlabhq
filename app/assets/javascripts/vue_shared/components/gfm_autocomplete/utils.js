import { escape, last } from 'lodash';
import { spriteIcon } from '~/lib/utils/common_utils';

const groupType = 'Group'; // eslint-disable-line @gitlab/require-i18n-strings

const nonWordOrInteger = /\W|^\d+$/;

export const GfmAutocompleteType = {
  Issues: 'issues',
  Labels: 'labels',
  Members: 'members',
  MergeRequests: 'mergeRequests',
  Milestones: 'milestones',
  Snippets: 'snippets',
};

function doesCurrentLineStartWith(searchString, fullText, selectionStart) {
  const currentLineNumber = fullText.slice(0, selectionStart).split('\n').length;
  const currentLine = fullText.split('\n')[currentLineNumber - 1];
  return currentLine.startsWith(searchString);
}

export const tributeConfig = {
  [GfmAutocompleteType.Issues]: {
    config: {
      trigger: '#',
      lookup: value => `${value.iid}${value.title}`,
      menuItemTemplate: ({ original }) =>
        `<small>${original.reference || original.iid}</small> ${escape(original.title)}`,
      selectTemplate: ({ original }) => original.reference || `#${original.iid}`,
    },
  },

  [GfmAutocompleteType.Labels]: {
    config: {
      trigger: '~',
      lookup: 'title',
      menuItemTemplate: ({ original }) => `
        <span class="dropdown-label-box" style="background: ${escape(original.color)};"></span>
        ${escape(original.title)}`,
      selectTemplate: ({ original }) =>
        nonWordOrInteger.test(original.title)
          ? `~"${escape(original.title)}"`
          : `~${escape(original.title)}`,
    },
    filterValues({ collection, fullText, selectionStart }) {
      if (doesCurrentLineStartWith('/label', fullText, selectionStart)) {
        return collection.filter(label => !label.set);
      }

      if (doesCurrentLineStartWith('/unlabel', fullText, selectionStart)) {
        return collection.filter(label => label.set);
      }

      return collection;
    },
  },

  [GfmAutocompleteType.Members]: {
    config: {
      trigger: '@',
      fillAttr: 'username',
      lookup: value =>
        value.type === groupType ? last(value.name.split(' / ')) : `${value.name}${value.username}`,
      menuItemTemplate: ({ original }) => {
        const commonClasses = 'gl-avatar gl-avatar-s24 gl-flex-shrink-0';
        const noAvatarClasses = `${commonClasses} gl-rounded-small
        gl-display-flex gl-align-items-center gl-justify-content-center`;

        const avatar = original.avatar_url
          ? `<img class="${commonClasses} gl-avatar-circle" src="${original.avatar_url}" alt="" />`
          : `<div class="${noAvatarClasses}" aria-hidden="true">
            ${original.username.charAt(0).toUpperCase()}</div>`;

        let displayName = original.name;
        let parentGroupOrUsername = `@${original.username}`;

        if (original.type === groupType) {
          const splitName = original.name.split(' / ');
          displayName = splitName.pop();
          parentGroupOrUsername = splitName.pop();
        }

        const count = original.count && !original.mentionsDisabled ? ` (${original.count})` : '';

        const disabledMentionsIcon = original.mentionsDisabled
          ? spriteIcon('notifications-off', 's16 gl-ml-3')
          : '';

        return `
        <div class="gl-display-flex gl-align-items-center">
          ${avatar}
          <div class="gl-font-sm gl-line-height-normal gl-ml-3">
            <div>${escape(displayName)}${count}</div>
            <div class="gl-text-gray-700">${escape(parentGroupOrUsername)}</div>
          </div>
          ${disabledMentionsIcon}
        </div>
      `;
      },
    },
    filterValues({ assignees, collection, fullText, selectionStart }) {
      if (doesCurrentLineStartWith('/assign', fullText, selectionStart)) {
        return collection.filter(member => !assignees.includes(member.username));
      }

      if (doesCurrentLineStartWith('/unassign', fullText, selectionStart)) {
        return collection.filter(member => assignees.includes(member.username));
      }

      return collection;
    },
  },

  [GfmAutocompleteType.MergeRequests]: {
    config: {
      trigger: '!',
      lookup: value => `${value.iid}${value.title}`,
      menuItemTemplate: ({ original }) =>
        `<small>${original.reference || original.iid}</small> ${escape(original.title)}`,
      selectTemplate: ({ original }) => original.reference || `!${original.iid}`,
    },
  },

  [GfmAutocompleteType.Milestones]: {
    config: {
      trigger: '%',
      lookup: 'title',
      menuItemTemplate: ({ original }) => escape(original.title),
      selectTemplate: ({ original }) => `%"${escape(original.title)}"`,
    },
  },

  [GfmAutocompleteType.Snippets]: {
    config: {
      trigger: '$',
      fillAttr: 'id',
      lookup: value => `${value.id}${value.title}`,
      menuItemTemplate: ({ original }) => `<small>${original.id}</small> ${escape(original.title)}`,
    },
  },
};
