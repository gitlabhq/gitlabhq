import redirectToCorrectPage from '~/blame/blame_redirect';
import { initBlamePreferences } from '~/blame/preferences/init_blame_preferences';
import initBlob from '~/pages/projects/init_blob';
import { initFindFileShortcut } from '~/projects/behaviors';

redirectToCorrectPage();
initBlamePreferences();
initBlob();
initFindFileShortcut();
