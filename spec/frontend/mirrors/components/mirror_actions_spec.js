import { mountExtended } from 'helpers/vue_test_utils_helper';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import MirrorActions from '~/mirrors/components/mirror_actions.vue';
import { createMirror, createPullMirror } from './mock_data';

describe('MirrorActions', () => {
  let wrapper;

  const createComponent = ({ mirror = createMirror() } = {}) => {
    wrapper = mountExtended(MirrorActions, {
      propsData: { mirror },
    });
  };

  const findSyncButton = () => wrapper.findByTestId('update-now-button');
  const findDeleteButton = () => wrapper.findByTestId('delete-mirror-button');
  const findDisableButton = () => wrapper.findByTestId('disable-mirror-button');
  const findEnableButton = () => wrapper.findByTestId('enable-mirror-button');
  const findCopyButton = () => wrapper.findByTestId('copy-public-key-button');

  describe('sync button', () => {
    it('is visible for an enabled push mirror', () => {
      createComponent();

      expect(findSyncButton().exists()).toBe(true);
    });

    it('is not visible for a disabled push mirror', () => {
      createComponent({ mirror: createMirror({ enabled: false }) });

      expect(findSyncButton().exists()).toBe(false);
    });

    it('is visible and disabled with "Updating" aria-label when updateStatus is started', () => {
      createComponent({ mirror: createMirror({ updateStatus: 'started' }) });

      const syncButton = findSyncButton();
      expect(syncButton.exists()).toBe(true);
      expect(syncButton.props('disabled')).toBe(true);
      expect(syncButton.attributes('aria-label')).toBe('Updating');
    });

    it('has spin icon class when updating', () => {
      createComponent({ mirror: createMirror({ updateStatus: 'started' }) });

      expect(findSyncButton().attributes('icon-classes')).toBe('spin');
    });

    it('has no spin icon class when not updating', () => {
      createComponent();

      expect(findSyncButton().attributes('icon-classes')).toBe('');
    });

    it('emits "sync" with mirror id on click', () => {
      const mirror = createMirror({ id: 7 });
      createComponent({ mirror });

      findSyncButton().vm.$emit('click');

      expect(wrapper.emitted('sync')).toEqual([[7]]);
    });
  });

  describe('toggle button', () => {
    it('shows disable button for an enabled push mirror', () => {
      createComponent();

      expect(findDisableButton().exists()).toBe(true);
      expect(findEnableButton().exists()).toBe(false);
    });

    it('shows enable button for a disabled push mirror', () => {
      createComponent({ mirror: createMirror({ enabled: false }) });

      expect(findEnableButton().exists()).toBe(true);
      expect(findDisableButton().exists()).toBe(false);
    });

    it('is not shown for a pull mirror', () => {
      createComponent({ mirror: createPullMirror() });

      expect(findDisableButton().exists()).toBe(false);
      expect(findEnableButton().exists()).toBe(false);
    });

    it('emits "toggle" with mirror id on click', () => {
      const mirror = createMirror({ id: 7 });
      createComponent({ mirror });

      findDisableButton().vm.$emit('click');

      expect(wrapper.emitted('toggle')).toEqual([[7]]);
    });
  });

  describe('delete button', () => {
    it('is always visible', () => {
      createComponent();

      expect(findDeleteButton().exists()).toBe(true);
    });

    it('emits "delete" with mirror id on click', () => {
      const mirror = createMirror({ id: 7 });
      createComponent({ mirror });

      findDeleteButton().vm.$emit('click');

      expect(wrapper.emitted('delete')).toEqual([[7]]);
    });
  });

  it('declares emits for sync, toggle, and delete', () => {
    createComponent();

    expect(wrapper.vm.$options.emits).toEqual(['sync', 'toggle', 'delete']);
  });

  describe('clipboard button', () => {
    it('is shown when sshKeyAuth is true and sshPublicKey is present', () => {
      createComponent({
        mirror: createMirror({ sshKeyAuth: true, sshPublicKey: 'ssh-rsa AAAA...' }),
      });

      const copyButton = wrapper.findComponent(ClipboardButton);
      expect(copyButton.exists()).toBe(true);
      expect(copyButton.props('text')).toBe('ssh-rsa AAAA...');
    });

    it('is not shown when sshKeyAuth is false', () => {
      createComponent();

      expect(findCopyButton().exists()).toBe(false);
    });

    it('is not shown when sshPublicKey is null', () => {
      createComponent({
        mirror: createMirror({ sshKeyAuth: true, sshPublicKey: null }),
      });

      expect(findCopyButton().exists()).toBe(false);
    });
  });
});
