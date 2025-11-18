import { GlForm, GlFormGroup, GlFormInput, GlModal, GlButton } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RestoreVersionModal from '~/wikis/components/restore_version_modal.vue';
import { getParameterByName } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/csrf', () => ({
  token: 'mocked-csrf-token',
}));

jest.mock('~/lib/utils/url_utility', () => ({
  getParameterByName: jest.fn(),
}));

Vue.use({});

describe('wikis/components/restore_version_modal', () => {
  let wrapper;

  const mockPageInfo = {
    path: '/project/wiki/page',
    title: 'Test Page',
    content: 'Test content',
    format: 'markdown',
    lastCommitSha: 'abc123def456',
    persisted: true,
  };

  const defaultProps = {
    modalId: 'wiki-restore-version-modal',
  };

  function buildWrapper() {
    wrapper = shallowMountExtended(RestoreVersionModal, {
      propsData: {
        ...defaultProps,
      },
      provide: {
        pageInfo: mockPageInfo,
      },
      stubs: {
        GlForm,
        GlModal,
        GlFormInput,
        GlFormGroup,
        GlButton,
      },
    });
  }

  const findModal = () => wrapper.findComponent({ name: 'GlModal' });
  const findForm = () => wrapper.findComponent({ name: 'GlForm' });

  describe('rendering', () => {
    it('renders the GlModal with right modalId props', () => {
      buildWrapper();

      expect(findModal().props('modalId')).toBe(defaultProps.modalId);
    });

    it('renders the form with correct attributes', () => {
      buildWrapper();

      expect(findForm().exists()).toBe(true);
      expect(findForm().attributes('action')).toBe(mockPageInfo.path);
      expect(findForm().attributes('method')).toBe('post');
    });
  });

  describe('form fields', () => {
    it('includes necessary input fields with proper values set', () => {
      getParameterByName.mockReturnValue('5');
      buildWrapper();

      const methodInput = wrapper.find('input[name="_method"]');
      const csrfInput = wrapper.find('input[name="authenticity_token"]');
      const commitShaInput = wrapper.find('input[name="wiki[last_commit_sha]"]');
      const titleInput = wrapper.find('input[name="wiki[title]"]');
      const contentInput = wrapper.find('input[name="wiki[content]"]');
      const formatInput = wrapper.find('input[name="wiki[format]"]');
      const commitMessageInput = wrapper
        .findComponent({ name: 'GlFormInput' })
        .find('input[name="wiki[message]"]');

      expect(methodInput.attributes('value')).toBe('put');
      expect(methodInput.attributes('type')).toBe('hidden');

      expect(csrfInput.attributes('type')).toBe('hidden');
      expect(csrfInput.attributes('value')).toBe('mocked-csrf-token');

      expect(commitShaInput.attributes('value')).toBe(mockPageInfo.lastCommitSha);
      expect(commitShaInput.attributes('type')).toBe('hidden');

      expect(titleInput.attributes('value')).toBe(mockPageInfo.title);
      expect(titleInput.attributes('type')).toBe('hidden');

      expect(contentInput.attributes('value')).toBe(mockPageInfo.content);
      expect(contentInput.attributes('type')).toBe('hidden');

      expect(formatInput.attributes('value')).toBe(mockPageInfo.format);
      expect(formatInput.attributes('type')).toBe('hidden');

      expect(commitMessageInput.attributes('required')).not.toBe(undefined);
      expect(commitMessageInput.element.value).toBe('Restored from v5');
    });
  });

  describe('form submission', () => {
    it('prevents default and submits form', async () => {
      buildWrapper();

      const mockEvent = {
        preventDefault: jest.fn(),
        type: 'submit',
        target: {
          submit: jest.fn(),
        },
      };

      await findForm().vm.$emit('submit', mockEvent);
      await nextTick();

      expect(mockEvent.preventDefault).toHaveBeenCalledTimes(1);
      expect(mockEvent.target.submit).toHaveBeenCalledTimes(1);
    });
  });

  describe('component state', () => {
    it('sets commitMessage with version when version_number parameter exists', () => {
      getParameterByName.mockReturnValue('3');
      buildWrapper();

      expect(wrapper.vm.commitMessage).toBe('Restored from v3');
    });

    it('sets commitMessage with fallback when no version_number parameter is found', () => {
      getParameterByName.mockReturnValue(null);
      buildWrapper();

      expect(wrapper.vm.commitMessage).toBe('Restored from old version');
    });
  });
});
