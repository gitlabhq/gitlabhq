export const userMapper = ({ name: text, web_url: href, ...user } = {}) => ({
  text,
  href,
  ...user,
});

export const commandMapper = ({ text, href, keywords = [] } = {}) => ({
  text,
  href,
  keywords: keywords.join(''),
});
