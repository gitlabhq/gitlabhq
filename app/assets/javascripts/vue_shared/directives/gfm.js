import { sanitize } from '~/lib/dompurify';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

// Render GitLab-flavoured Markdown safely with a directive
export const gfm = (el, { value, oldValue }) => {
  if (oldValue === value) return;
  const fragment = sanitize(value, {
    RETURN_DOM_FRAGMENT: true,
  });
  el.textContent = '';
  el.appendChild(fragment);
  renderGFM(el);
};
