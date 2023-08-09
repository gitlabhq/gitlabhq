export const CUSTOM_EMOJI = [
  {
    id: 'gid://gitlab/CustomEmoji/1',
    name: 'confused_husky',
    url: 'https://gitlab.com/custom_emoji/custom_emoji/-/raw/main/img/confused_husky.gif',
    createdAt: 'created-at',
    userPermissions: {
      deleteCustomEmoji: false,
    },
  },
];

export const CREATED_CUSTOM_EMOJI = {
  data: {
    createCustomEmoji: {
      errors: [],
    },
  },
};

export const CREATED_CUSTOM_EMOJI_WITH_ERROR = {
  data: {
    createCustomEmoji: {
      errors: ['Test error'],
    },
  },
};
