import { getURLOrigin } from '~/lib/utils/url_utility';
import { ALLOWED_VIDEO_ORIGINS } from '../../constants';
import { buildUneditableHtmlAsTextTokens } from './build_uneditable_token';

const isVideoFrame = (html) => {
  const parser = new DOMParser();
  const doc = parser.parseFromString(html, 'text/html');
  const {
    children: { length },
  } = doc;
  const iframe = doc.querySelector('iframe');
  const origin = iframe && getURLOrigin(iframe.getAttribute('src'));

  return length === 1 && ALLOWED_VIDEO_ORIGINS.includes(origin);
};

const canRender = ({ type, literal }) => {
  return type === 'htmlBlock' && !isVideoFrame(literal);
};

const render = (node) => buildUneditableHtmlAsTextTokens(node);

export default { canRender, render };
