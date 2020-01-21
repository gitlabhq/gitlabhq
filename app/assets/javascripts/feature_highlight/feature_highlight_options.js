import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { highlightFeatures } from './feature_highlight';

export default function domContentLoaded() {
  if (bp.getBreakpointSize() === 'xl') {
    highlightFeatures();
    return true;
  }
  return false;
}

document.addEventListener('DOMContentLoaded', domContentLoaded);
