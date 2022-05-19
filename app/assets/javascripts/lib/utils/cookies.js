import CookiesBuilder from 'js-cookie';

// set default path for cookies
const Cookies = CookiesBuilder.withAttributes({
  path: gon.relative_url_root || '/',
});

export default Cookies;
