const buildToken = (type, tagName, props) => {
  return { type, tagName, ...props };
};

const TAG_TYPES = {
  block: 'div',
  inline: 'span',
};

export const buildUneditableOpenTokens = (token, type = TAG_TYPES.block) => {
  return [
    buildToken('openTag', type, {
      attributes: { contenteditable: false },
      classNames: [
        'gl-px-4 gl-py-2 gl-opacity-5 gl-bg-gray-100 gl-user-select-none gl-cursor-not-allowed',
      ],
    }),
    token,
  ];
};

export const buildUneditableCloseToken = (type = TAG_TYPES.block) => buildToken('closeTag', type);

export const buildUneditableCloseTokens = (token, type = TAG_TYPES.block) => {
  return [token, buildUneditableCloseToken(type)];
};

export const buildUneditableInlineTokens = token => {
  return [
    ...buildUneditableOpenTokens(token, TAG_TYPES.inline),
    buildUneditableCloseToken(TAG_TYPES.inline),
  ];
};

export const buildUneditableTokens = token => {
  return [...buildUneditableOpenTokens(token), buildUneditableCloseToken()];
};
