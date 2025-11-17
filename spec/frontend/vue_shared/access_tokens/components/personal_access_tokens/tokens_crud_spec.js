import { GlBadge, GlDisclosureDropdown, GlDisclosureDropdownItem, GlModal } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { RENDER_ALL_SLOTS_TEMPLATE, stubComponent } from 'helpers/stub_component';
import TokensCrud from '~/vue_shared/access_tokens/components/personal_access_tokens/tokens_crud.vue';
import TokensTable from '~/vue_shared/access_tokens/components/personal_access_tokens/tokens_table.vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import DetailsDrawer from '~/vue_shared/access_tokens/components/personal_access_tokens/details_drawer.vue';
import ConfirmActionModal from '~/vue_shared/components/confirm_action_modal.vue';
import { useAccessTokens } from '~/vue_shared/access_tokens/stores/access_tokens';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(PiniaVuePlugin);

describe('Personal access tokens crud component', () => {
  let wrapper;
  const pinia = createTestingPinia();
  const store = useAccessTokens();
  const tokens = [
    { id: 1, name: 'Token 1', expiresAt: '2025-10-05' },
    { id: 2, name: 'Token 2', expiresAt: '2025-09-14' },
  ];
  const createWrapper = () => {
    wrapper = shallowMountExtended(TokensCrud, {
      pinia,
      propsData: { tokens, loading: false },
      provide: { accessTokenNew: 'new/path' },
      stubs: {
        GlDisclosureDropdown,
        ConfirmActionModal,
        CrudComponent: stubComponent(CrudComponent, {
          template: RENDER_ALL_SLOTS_TEMPLATE,
        }),
      },
    });
  };

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findNewTokenDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findTokensTable = () => wrapper.findComponent(TokensTable);
  const findDetailsDrawer = () => wrapper.findComponent(DetailsDrawer);
  const findConfirmActionModal = () => wrapper.findComponent(ConfirmActionModal);

  const confirmModal = () => {
    findConfirmActionModal()
      .findComponent(GlModal)
      .vm.$emit('primary', { preventDefault: jest.fn() });

    return waitForPromises();
  };

  describe('on page load', () => {
    beforeEach(() => createWrapper());

    it('shows crud component', () => {
      expect(findCrudComponent().props('title')).toBe('Personal access tokens');
    });

    it('shows new tokens dropdown', () => {
      expect(findNewTokenDropdown().props()).toMatchObject({
        toggleText: 'Generate token',
        placement: 'bottom-end',
        fluidWidth: true,
      });
    });

    it('shows tokens table', () => {
      expect(findTokensTable().props()).toMatchObject({ tokens, loading: false });
    });

    it('shows details drawer', () => {
      expect(findDetailsDrawer().props('token')).toBe(null);
    });

    describe('when table selects a token', () => {
      beforeEach(() => findTokensTable().vm.$emit('select', tokens[1]));

      it('passes selected token to drawer', () => {
        expect(findDetailsDrawer().props('token')).toBe(tokens[1]);
      });

      it('clears selected token when drawer closes', async () => {
        findDetailsDrawer().vm.$emit('close');
        await nextTick();

        expect(findDetailsDrawer().props('token')).toBe(null);
      });
    });

    describe('fine-grained token dropdown option', () => {
      it('shows option text', () => {
        expect(findDropdownItems().at(0).text()).toContain('Fine-grained token');
      });

      it('shows beta badge', () => {
        const badge = findDropdownItems().at(0).findComponent(GlBadge);

        expect(badge.props('variant')).toBe('info');
        expect(badge.text()).toBe('Beta');
      });

      it('shows option description', () => {
        expect(findDropdownItems().at(0).text()).toContain(
          'Limit scope to specific groups and projects and fine-grained permissions to resources.',
        );
      });
    });

    describe('broad-access token dropdown option', () => {
      it('shows option text', () => {
        expect(findDropdownItems().at(1).text()).toContain('Broad-access token');
      });

      it('shows option description', () => {
        expect(findDropdownItems().at(1).text()).toContain(
          'Scoped to all groups and projects with broad permissions to resources.',
        );
      });
    });

    describe.each`
      type                | findComponent
      ${'tokens table'}   | ${findTokensTable}
      ${'details drawer'} | ${findDetailsDrawer}
    `('for $type', ({ findComponent }) => {
      it('shows confirm action modal for token rotate', async () => {
        findComponent().vm.$emit('rotate', tokens[1]);
        await nextTick();

        expect(findConfirmActionModal().props()).toMatchObject({
          modalId: 'token-action-confirm-modal',
          title: "Rotate the token 'Token 2'?",
          actionText: 'Rotate',
        });
      });

      it('shows confirm action modal for token revoke', async () => {
        findComponent().vm.$emit('revoke', tokens[1]);
        await nextTick();

        expect(findConfirmActionModal().props()).toMatchObject({
          modalId: 'token-action-confirm-modal',
          title: "Revoke the token 'Token 2'?",
          actionText: 'Revoke',
        });
      });
    });

    describe.each`
      event       | storeAction          | expectedParameters
      ${'rotate'} | ${store.rotateToken} | ${[2, '2025-09-14']}
      ${'revoke'} | ${store.revokeToken} | ${[2]}
    `('for $event confirm modal', ({ event, storeAction, expectedParameters }) => {
      beforeEach(() => {
        findTokensTable().vm.$emit('select', tokens[1]);
        findDetailsDrawer().vm.$emit(event, tokens[1]);
      });

      it('unrenders modal when the modal closes', async () => {
        findConfirmActionModal().vm.$emit('close');
        await nextTick();

        expect(findConfirmActionModal().exists()).toBe(false);
      });

      describe('when modal is confirmed', () => {
        beforeEach(() => confirmModal());

        it(`performs token ${event}`, () => {
          expect(storeAction).toHaveBeenCalledTimes(1);
          expect(storeAction).toHaveBeenCalledWith(...expectedParameters);
        });

        it('closes details drawer', () => {
          expect(findDetailsDrawer().props('token')).toBe(null);
        });
      });
    });
  });
});
