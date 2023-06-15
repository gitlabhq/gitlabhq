import { GlLoadingIcon, GlModal } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import getNoWritableForksResponse from 'test_fixtures/graphql/vue_shared/components/web_ide/get_writable_forks.query.graphql_none.json';
import getSomeWritableForksResponse from 'test_fixtures/graphql/vue_shared/components/web_ide/get_writable_forks.query.graphql_some.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ConfirmForkModal, { i18n } from '~/vue_shared/components/web_ide/confirm_fork_modal.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import getWritableForksQuery from '~/vue_shared/components/web_ide/get_writable_forks.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';

describe('vue_shared/components/confirm_fork_modal', () => {
  Vue.use(VueApollo);

  let wrapper = null;

  const forkPath = '/fake/fork/path';
  const modalId = 'confirm-fork-modal';
  const defaultProps = { modalId, forkPath };

  const findModal = () => wrapper.findComponent(GlModal);
  const findModalProp = (prop) => findModal().props(prop);
  const findModalActionProps = () => findModalProp('actionPrimary');

  const createComponent = (props = {}, getWritableForksResponse = getNoWritableForksResponse) => {
    const fakeApollo = createMockApollo([
      [getWritableForksQuery, jest.fn().mockResolvedValue(getWritableForksResponse)],
    ]);
    return shallowMountExtended(ConfirmForkModal, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      apolloProvider: fakeApollo,
    });
  };

  describe('visible = false', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('sets the visible prop to `false`', () => {
      expect(findModalProp('visible')).toBe(false);
    });

    it('sets the modal title', () => {
      const title = findModalProp('title');
      expect(title).toBe(i18n.title);
    });

    it('sets the modal id', () => {
      const fakeModalId = findModalProp('modalId');
      expect(fakeModalId).toBe(modalId);
    });

    it('has the fork path button', () => {
      const modalProps = findModalActionProps();
      expect(modalProps.text).toBe(i18n.btnText);
      expect(modalProps.attributes.variant).toBe('confirm');
    });

    it('sets the correct fork path', () => {
      const modalProps = findModalActionProps();
      expect(modalProps.attributes.href).toBe(forkPath);
    });

    it('has the fork message', () => {
      expect(findModal().text()).toContain(i18n.message);
    });
  });

  describe('visible = true', () => {
    beforeEach(() => {
      wrapper = createComponent({ visible: true });
    });

    it('sets the visible prop to `true`', () => {
      expect(findModalProp('visible')).toBe(true);
    });

    it('emits the `change` event if the modal is hidden', () => {
      expect(wrapper.emitted('change')).toBeUndefined();

      findModal().vm.$emit('change', false);

      expect(wrapper.emitted('change')).toEqual([[false]]);
    });
  });

  describe('writable forks', () => {
    describe('when loading', () => {
      it('shows loading spinner', () => {
        wrapper = createComponent();

        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      });
    });

    describe('with no writable forks', () => {
      it('contains `newForkMessage`', async () => {
        wrapper = createComponent();

        await waitForPromises();

        expect(wrapper.text()).toContain(i18n.newForkMessage);
      });
    });

    describe('with writable forks', () => {
      it('contains `existingForksMessage`', async () => {
        wrapper = createComponent(null, getSomeWritableForksResponse);

        await waitForPromises();

        expect(wrapper.text()).toContain(i18n.existingForksMessage);
      });

      it('renders links to the forks', async () => {
        wrapper = createComponent(null, getSomeWritableForksResponse);

        await waitForPromises();

        const forks = getSomeWritableForksResponse.data.project.visibleForks.nodes;

        expect(wrapper.findByText(forks[0].fullPath).attributes('href')).toBe(forks[0].webUrl);
        expect(wrapper.findByText(forks[1].fullPath).attributes('href')).toBe(forks[1].webUrl);
      });
    });
  });
});
