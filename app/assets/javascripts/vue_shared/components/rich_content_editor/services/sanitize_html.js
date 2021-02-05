import createSanitizer from 'dompurify';
import { getURLOrigin } from '~/lib/utils/url_utility';
import { ALLOWED_VIDEO_ORIGINS } from '../constants';

const sanitizer = createSanitizer(window);
const ADD_TAGS = ['iframe'];

sanitizer.addHook('uponSanitizeElement', (node) => {
  if (node.tagName !== 'IFRAME') {
    return;
  }

  const origin = getURLOrigin(node.getAttribute('src'));

  if (!ALLOWED_VIDEO_ORIGINS.includes(origin)) {
    node.remove();
  }
});

const sanitize = (content) => sanitizer.sanitize(content, { ADD_TAGS });

export default sanitize;
