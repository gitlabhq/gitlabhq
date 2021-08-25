export const markInputRegex = (tag) =>
  new RegExp(`(<(${tag})((?: \\w+=".+?")+)?>([^<]+)</${tag}>)$`, 'gm');

export const extractMarkAttributesFromMatch = ([, , , attrsString]) => {
  const attrRegex = /(\w+)="(.+?)"/g;
  const attrs = {};

  let key;
  let value;

  do {
    [, key, value] = attrRegex.exec(attrsString) || [];
    if (key) attrs[key] = value;
  } while (key);

  return attrs;
};
