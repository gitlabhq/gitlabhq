const buildToken = (type, tagName, props) => {
  return { type, tagName, ...props };
};

export const buildUneditableOpenTokens = token => {
  return [
    buildToken('openTag', 'div', {
      attributes: { contenteditable: false },
      classNames: [
        'gl-px-4 gl-py-2 gl-opacity-5 gl-bg-gray-100 gl-user-select-none gl-cursor-not-allowed',
      ],
    }),
    token,
  ];
};

export const buildUneditableCloseToken = () => buildToken('closeTag', 'div');

export const buildUneditableCloseTokens = token => {
  return [token, buildToken('closeTag', 'div')];
};

export const buildUneditableTokens = token => {
  return [...buildUneditableOpenTokens(token), buildUneditableCloseToken()];
};
