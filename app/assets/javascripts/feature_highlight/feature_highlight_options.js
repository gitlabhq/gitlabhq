import { highlightFeatures } from './feature_highlight';
import bp from '../breakpoints';

export default function domContentLoaded() {
  if (bp.getBreakpointSize() === 'lg') {
    highlightFeatures();
    return true;
  }
  return false;
}

document.addEventListener('DOMContentLoaded', domContentLoaded);
