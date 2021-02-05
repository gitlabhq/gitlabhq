import { escape, last } from 'lodash';
import * as Emoji from '~/emoji';
import { spriteIcon } from '~/lib/utils/common_utils';

const groupType = 'Group'; // eslint-disable-line @gitlab/require-i18n-strings

// Number of users to show in the autocomplete menu to avoid doing a mass fetch of 100+ avatars
const memberLimit = 10;

const nonWordOrInteger = /\W|^\d+$/;

export const menuItemLimit = 100;

export const GfmAutocompleteType = {
  Emojis: 'emojis',
  Issues: 'issues',
  Labels: 'labels',
  Members: 'members',
  MergeRequests: 'mergeRequests',
  Milestones: 'milestones',
  QuickActions: 'commands',
  Snippets: 'snippets',
};

function doesCurrentLineStartWith(searchString, fullText, selectionStart) {
  const currentLineNumber = fullText.slice(0, selectionStart).split('\n').length;
  const currentLine = fullText.split('\n')[currentLineNumber - 1];
  return currentLine.startsWith(searchString);
}

export const tributeConfig = {
  [GfmAutocompleteType.Emojis]: {
    config: {
      trigger: ':',
      lookup: (value) => value,
      menuItemLimit,
      menuItemTemplate: ({ original }) => `${original} ${Emoji.glEmojiTag(original)}`,
      selectTemplate: ({ original }) => `:${original}:`,
    },
  },

  [GfmAutocompleteType.Issues]: {
    config: {
      trigger: '#',
      lookup: (value) => `${value.iid}${value.title}`,
      menuItemLimit,
      menuItemTemplate: ({ original }) =>
        `<small>${original.reference || original.iid}</small> ${escape(original.title)}`,
      selectTemplate: ({ original }) => original.reference || `#${original.iid}`,
    },
  },

  [GfmAutocompleteType.Labels]: {
    config: {
      trigger: '~',
      lookup: 'title',
      menuItemLimit,
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
        return collection.filter((label) => !label.set);
      }

      if (doesCurrentLineStartWith('/unlabel', fullText, selectionStart)) {
        return collection.filter((label) => label.set);
      }

      return collection;
    },
  },

  [GfmAutocompleteType.Members]: {
    config: {
      trigger: '@',
      fillAttr: 'username',
      lookup: (value) =>
        value.type === groupType ? last(value.name.split(' / ')) : `${value.name}${value.username}`,
      menuItemLimit: memberLimit,
      menuItemTemplate: ({ original }) => {
        const commonClasses = 'gl-avatar gl-avatar-s32 gl-flex-shrink-0';
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
          <div class="gl-line-height-normal gl-ml-4">
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
        return collection.filter((member) => !assignees.includes(member.username));
      }

      if (doesCurrentLineStartWith('/unassign', fullText, selectionStart)) {
        return collection.filter((member) => assignees.includes(member.username));
      }

      return collection;
    },
  },

  [GfmAutocompleteType.MergeRequests]: {
    config: {
      trigger: '!',
      lookup: (value) => `${value.iid}${value.title}`,
      menuItemLimit,
      menuItemTemplate: ({ original }) =>
        `<small>${original.reference || original.iid}</small> ${escape(original.title)}`,
      selectTemplate: ({ original }) => original.reference || `!${original.iid}`,
    },
  },

  [GfmAutocompleteType.Milestones]: {
    config: {
      trigger: '%',
      lookup: 'title',
      menuItemLimit,
      menuItemTemplate: ({ original }) => escape(original.title),
      selectTemplate: ({ original }) => `%"${escape(original.title)}"`,
    },
  },

  [GfmAutocompleteType.QuickActions]: {
    config: {
      trigger: '/',
      fillAttr: 'name',
      lookup: (value) => `${value.name}${value.aliases.join()}`,
      menuItemLimit,
      menuItemTemplate: ({ original }) => {
        const aliases = original.aliases.length
          ? `<small>(or /${original.aliases.join(', /')})</small>`
          : '';

        const params = original.params.length ? `<small>${original.params.join(' ')}</small>` : '';

        let description = '';

        if (original.warning) {
          const confidentialIcon =
            original.icon === 'confidential' ? spriteIcon('eye-slash', 's16 gl-mr-2') : '';
          description = `<small>${confidentialIcon}<em>${original.warning}</em></small>`;
        } else if (original.description) {
          description = `<small><em>${original.description}</em></small>`;
        }

        return `<div>/${original.name} ${aliases} ${params}</div>
          <div>${description}</div>`;
      },
    },
  },

  [GfmAutocompleteType.Snippets]: {
    config: {
      trigger: '$',
      fillAttr: 'id',
      lookup: (value) => `${value.id}${value.title}`,
      menuItemLimit,
      menuItemTemplate: ({ original }) => `<small>${original.id}</small> ${escape(original.title)}`,
    },
  },
};
