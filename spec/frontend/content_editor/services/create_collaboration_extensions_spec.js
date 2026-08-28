import * as Y from 'yjs';
import { Awareness } from 'y-protocols/awareness';
import { assignUserColor } from '~/collaborative_editing/user_colors';
import createCollaborationExtensions from '~/content_editor/services/create_collaboration_extensions';

describe('content_editor/services/create_collaboration_extensions', () => {
  const remoteClientId = 42;

  let provider;
  let identities;

  const findCursorExtension = () =>
    createCollaborationExtensions({ provider }).find((e) => e.name === 'collaborationCursor');

  // y-prosemirror calls render(user, clientId), where `user` is the peer-authored
  // awareness state and `clientId` is the value the server stamped on the relay.
  const renderCursorFor = (clientId, awarenessUser = {}) =>
    findCursorExtension().options.render(awarenessUser, clientId);

  beforeEach(() => {
    const doc = new Y.Doc();
    const awareness = new Awareness(doc);
    identities = new Map();

    provider = {
      doc,
      awareness,
      identityFor: (clientId) => identities.get(clientId) ?? null,
    };
  });

  it('shares the provider document with the collaboration extension', () => {
    const collaboration = createCollaborationExtensions({ provider }).find(
      (e) => e.name === 'collaboration',
    );

    expect(collaboration.options.document).toBe(provider.doc);
  });

  describe('cursor rendering', () => {
    beforeEach(() => {
      identities.set(remoteClientId, { id: 7, name: 'Bertha' });
    });

    it('labels the caret with the collaborator name', () => {
      const caret = renderCursorFor(remoteClientId);

      expect(caret.textContent).toBe('Bertha');
    });

    it('hides the caret from screen readers so names are not read as prose', () => {
      const caret = renderCursorFor(remoteClientId);

      expect(caret.getAttribute('aria-hidden')).toBe('true');
    });

    it('colours the caret and its label from the user id', () => {
      const caret = renderCursorFor(remoteClientId);
      // jsdom resolves colour properties to rgb(), so compare against a
      // reference element rather than the authored hex.
      const reference = document.createElement('span');
      reference.style.backgroundColor = assignUserColor(7);

      expect(caret.style.borderColor).not.toBe('');
      expect(caret.firstChild.style.backgroundColor).toBe(reference.style.backgroundColor);
    });

    it('ignores a name and colour the peer put in its own awareness state', () => {
      const caret = renderCursorFor(remoteClientId, {
        name: 'Administrator',
        color: '#ff0000',
      });

      expect(caret.textContent).toBe('Bertha');
      expect(caret.firstChild.style.backgroundColor).not.toBe('rgb(255, 0, 0)');
    });
  });

  describe('when the server stamped no identity for the client', () => {
    it('falls back rather than trusting the awareness state', () => {
      const caret = renderCursorFor(remoteClientId, {
        name: 'Administrator',
        color: '#ff0000',
      });

      expect(caret.textContent).toBe('Unknown user');
      expect(caret.style.borderColor).not.toBe('');
      expect(caret.firstChild.style.backgroundColor).not.toBe('rgb(255, 0, 0)');
    });
  });
});
