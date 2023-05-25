import initFilePickers from '~/file_pickers';
import ZenMode from '~/zen_mode';
import { initRemoveAvatar } from '~/admin/topics';
import { mountMarkdownEditor } from '~/vue_shared/components/markdown/mount_markdown_editor';

initFilePickers();
new ZenMode(); // eslint-disable-line no-new

initRemoveAvatar();
mountMarkdownEditor();
