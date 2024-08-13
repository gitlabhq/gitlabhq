import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon, GlModal, GlAlert } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import SignatureDetailsModal from '~/packages_and_registries/container_registry/explorer/components/details_page/signature_details_modal.vue';
import getManifestDetailsQuery from '~/packages_and_registries/container_registry/explorer/graphql/queries/get_manifest_details.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import CodeBlockHighlighted from '~/vue_shared/components/code_block_highlighted.vue';

Vue.use(VueApollo);

describe('Signature details modal', () => {
  let wrapper;

  const defaultManifestDetailsHandler = jest
    .fn()
    .mockResolvedValue({ data: { containerRepository: { id: 1, manifest: 'manifest details' } } });

  const createWrapper = ({
    manifestDetailsHandler = defaultManifestDetailsHandler,
    visible = true,
    digest = 'sha256:abcdef',
  } = {}) => {
    wrapper = shallowMount(SignatureDetailsModal, {
      propsData: { visible, digest },
      apolloProvider: createMockApollo([[getManifestDetailsQuery, manifestDetailsHandler]]),
      mocks: { $route: { params: { id: 123 } } },
    });

    return waitForPromises();
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findCodeBlockHighlighted = () => wrapper.findComponent(CodeBlockHighlighted);

  describe('modal', () => {
    it('shows modal with expected settings', () => {
      createWrapper();

      expect(findModal().attributes()).toHaveProperty('scrollable');
      expect(findModal().props()).toMatchObject({
        title: 'Signature details',
        actionCancel: { text: 'Close' },
      });
    });

    it.each([true, false])('passes %s visible prop', (visible) => {
      createWrapper({ visible });

      expect(findModal().props('visible')).toBe(visible);
    });

    it('emits close event when modal is closed', () => {
      createWrapper();
      findModal().vm.$emit('hidden');

      expect(wrapper.emitted('close')).toHaveLength(1);
    });
  });

  describe('manifest details query', () => {
    it('calls query with expected variables', () => {
      createWrapper();

      expect(defaultManifestDetailsHandler).toHaveBeenCalledTimes(1);
      expect(defaultManifestDetailsHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/ContainerRepository/123',
        reference: 'sha256:abcdef',
      });
    });

    it('does not call query when there is no digest', () => {
      createWrapper({ digest: null });

      expect(defaultManifestDetailsHandler).not.toHaveBeenCalled();
    });
  });

  describe('when query is loading', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not show error alert', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('does not show code block', () => {
      expect(findCodeBlockHighlighted().exists()).toBe(false);
    });
  });

  describe('when query encounters an error', () => {
    beforeEach(() => {
      return createWrapper({ manifestDetailsHandler: jest.fn().mockRejectedValue() });
    });

    it('does not show loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('shows error alert with expected props and text', () => {
      expect(findAlert().props()).toMatchObject({
        variant: 'danger',
        dismissible: false,
      });
    });

    it('shows error alert with expected text', () => {
      expect(findAlert().text()).toBe('Could not load signature details.');
    });

    it('does not show code block', () => {
      expect(findCodeBlockHighlighted().exists()).toBe(false);
    });
  });

  describe('when query finishes loading', () => {
    beforeEach(() => {
      return createWrapper();
    });

    it('does not show loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('does not show error alert', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('shows code block with expected props', () => {
      expect(findCodeBlockHighlighted().props()).toMatchObject({
        language: 'json',
        code: 'manifest details',
      });
    });
  });
});
