import CookiesBuilder from 'js-cookie';

// set default path for cookies
const Cookies = CookiesBuilder.withAttributes({
  // eslint-disable-next-line @gitlab/no-hardcoded-urls -- cookie path config using relative_url_root, not a hardcoded URL
  path: gon.relative_url_root || '/',
});

export default Cookies;
