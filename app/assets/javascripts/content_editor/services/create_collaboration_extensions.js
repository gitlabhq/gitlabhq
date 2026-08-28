import { GL_COLOR_DATA_BLUE_500 } from '@gitlab/ui/src/tokens/build/js/tokens';
import Collaboration from '@tiptap/extension-collaboration';
import CollaborationCursor from '@tiptap/extension-collaboration-cursor';
import { assignUserColor } from '~/collaborative_editing/user_colors';
import { __ } from '~/locale';

const FALLBACK_COLOR = GL_COLOR_DATA_BLUE_500;
const FRAGMENT_FIELD = 'default';

function buildCursorRenderer(provider) {
  return function renderCursor(_user, clientId) {
    const identity = provider.identityFor(clientId);
    const color = identity ? assignUserColor(identity.id) : FALLBACK_COLOR;

    const caret = document.createElement('span');
    caret.classList.add('collaboration-cursor-caret');
    caret.style.borderColor = color;
    caret.setAttribute('aria-hidden', 'true');

    const label = document.createElement('span');
    label.classList.add('collaboration-cursor-label');
    label.style.backgroundColor = color;
    label.textContent = identity?.name || __('Unknown user');

    caret.appendChild(label);

    return caret;
  };
}

export default function createCollaborationExtensions({ provider }) {
  return [
    Collaboration.configure({
      document: provider.doc,
      field: FRAGMENT_FIELD,
    }),
    CollaborationCursor.configure({
      provider,
      render: buildCursorRenderer(provider),
    }),
  ];
}
