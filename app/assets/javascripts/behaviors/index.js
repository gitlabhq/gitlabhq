import './autosize';
import './bind_in_out';
import './markdown/render_gfm';
import initCopyAsGFM from './markdown/copy_as_gfm';
import initCopyToClipboard from './copy_to_clipboard';
import './details_behavior';
import installGlEmojiElement from './gl_emoji';
import './quick_submit';
import './requires_input';
import './toggler_behavior';
import '../preview_markdown';

installGlEmojiElement();
initCopyAsGFM();
initCopyToClipboard();
