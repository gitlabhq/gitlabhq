import { nextTick } from 'vue';
import * as Y from 'yjs';
import { Awareness } from 'y-protocols/awareness';
import { GlAvatarsInline } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import CollaboratorsIndicator from '~/collaborative_editing/components/collaborators_indicator.vue';
import { assignUserColor } from '~/collaborative_editing/user_colors';

describe('CollaboratorsIndicator', () => {
  let wrapper;
  let doc;
  let awareness;
  let identities;

  const findAvatars = () => wrapper.findComponent(GlAvatarsInline);

  const addRemoteCollaborator = async (clientId, { identity, awarenessState = {} } = {}) => {
    if (identity) identities.set(clientId, identity);

    awareness.states.set(clientId, awarenessState);
    awareness.emit('change', [{ added: [clientId], updated: [], removed: [] }]);

    await nextTick();
  };

  const createWrapper = () => {
    doc = new Y.Doc();
    awareness = new Awareness(doc);
    identities = new Map();

    wrapper = mountExtended(CollaboratorsIndicator, {
      propsData: {
        provider: { doc, awareness, identityFor: (clientId) => identities.get(clientId) ?? null },
      },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  it('renders nothing when editing alone', () => {
    expect(findAvatars().exists()).toBe(false);
  });

  it('renders an avatar for another collaborator', async () => {
    await addRemoteCollaborator(2, {
      identity: { id: 7, name: 'Bertha', avatarUrl: '/bertha.png' },
    });

    expect(findAvatars().props('avatars')).toMatchObject([
      { name: 'Bertha', avatarUrl: '/bertha.png' },
    ]);
  });

  it('derives the colour from the user id rather than the awareness state', async () => {
    await addRemoteCollaborator(2, {
      identity: { id: 7, name: 'Bertha' },
      awarenessState: { user: { color: '#ff0000' } },
    });

    expect(findAvatars().props('avatars')).toMatchObject([{ color: assignUserColor(7) }]);
  });

  it('excludes the local client from the list', async () => {
    identities.set(doc.clientID, { id: 1, name: 'Local user' });

    await addRemoteCollaborator(2, { identity: { id: 7, name: 'Bertha' } });

    expect(findAvatars().props('avatars')).not.toContainEqual(
      expect.objectContaining({ name: 'Local user' }),
    );
  });

  it('ignores a client the server has not stamped an identity for', async () => {
    await addRemoteCollaborator(3);

    expect(findAvatars().exists()).toBe(false);
  });

  describe('when a peer claims an identity in its own awareness state', () => {
    it('does not render the claimed name or avatar', async () => {
      await addRemoteCollaborator(2, {
        identity: { id: 7, name: 'Bertha', avatarUrl: '/bertha.png' },
        awarenessState: {
          user: { id: 99, name: 'Administrator', avatarUrl: 'https://evil.test/beacon.png' },
        },
      });

      expect(findAvatars().props('avatars')).toMatchObject([
        { name: 'Bertha', avatarUrl: '/bertha.png' },
      ]);
    });

    it('renders nothing when the server stamped no identity at all', async () => {
      await addRemoteCollaborator(2, {
        awarenessState: {
          user: { id: 99, name: 'Administrator', avatarUrl: 'https://evil.test/beacon.png' },
        },
      });

      expect(findAvatars().exists()).toBe(false);
    });
  });

  it('removes a collaborator once they leave', async () => {
    await addRemoteCollaborator(2, { identity: { id: 7, name: 'Bertha' } });

    awareness.states.delete(2);
    awareness.emit('change', [{ added: [], updated: [], removed: [2] }]);
    await nextTick();

    expect(findAvatars().exists()).toBe(false);
  });

  it('collapses the two clients of one person editing in two tabs', async () => {
    await addRemoteCollaborator(2, { identity: { id: 7, name: 'Bertha' } });
    await addRemoteCollaborator(3, { identity: { id: 7, name: 'Bertha' } });

    expect(findAvatars().props('avatars')).toMatchObject([{ name: 'Bertha' }]);
  });

  describe('when more collaborators join than the indicator shows', () => {
    const addCollaborators = (count) =>
      Promise.all(
        Array.from({ length: count }, (_, index) => index + 2).map((clientId) =>
          addRemoteCollaborator(clientId, {
            identity: { id: clientId, name: `Collaborator ${clientId}` },
          }),
        ),
      );

    it('shows every avatar while at the limit', async () => {
      await addCollaborators(5);

      expect(findAvatars().props('avatars')).toHaveLength(5);
      expect(wrapper.findByTestId('collapsed-avatars-badge').exists()).toBe(false);
    });

    it('announces the hidden count once above the limit', async () => {
      await addCollaborators(6);

      expect(findAvatars().props()).toMatchObject({
        maxVisible: 5,
        collapsed: true,
        badgeSrOnlyText: '1 more person editing',
      });
      expect(findAvatars().attributes('aria-label')).toBe('6 other people editing');
    });

    it('pluralises the hidden count', async () => {
      await addCollaborators(8);

      expect(findAvatars().props('badgeSrOnlyText')).toBe('3 more people editing');
    });
  });

  it('stops listening for awareness changes once destroyed', () => {
    jest.spyOn(awareness, 'off');

    wrapper.destroy();

    expect(awareness.off).toHaveBeenCalledWith('change', expect.any(Function));
  });
});
