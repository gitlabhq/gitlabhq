import { GlModal } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import RevokeButton from '~/deploy_tokens/components/revoke_button.vue';

const mockToken = {
  created_at: '2021-03-18T19:13:03.011Z',
  deploy_token_type: 'project_type',
  expires_at: null,
  id: 1,
  name: 'testtoken',
  read_package_registry: true,
  read_registry: false,
  read_repository: true,
  revoked: false,
  token: 'xUVsGDfK4y_Xj5UhqvaH',
  token_encrypted: 'JYeg+WK4obIlrhyAYWvBvaY7CNB/U3FPX3cdLrivAly5qToy',
  username: 'gitlab+deploy-token-1',
  write_package_registry: true,
  write_registry: false,
};
const mockRevokePath = '';

describe('RevokeButton', () => {
  let wrapper;
  let glModalDirective;

  function createComponent(injectedProperties = {}) {
    glModalDirective = jest.fn();
    return extendedWrapper(
      mount(RevokeButton, {
        provide: {
          token: mockToken,
          revokePath: mockRevokePath,
          ...injectedProperties,
        },
        directives: {
          glModal: {
            bind(_, { value }) {
              glModalDirective(value);
            },
          },
        },
        stubs: {
          GlModal: stubComponent(GlModal, {
            template:
              '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
          }),
        },
      }),
    );
  }

  afterEach(() => {
    wrapper.destroy();
  });

  const findRevokeButton = () => wrapper.findByTestId('revoke-button');
  const findModal = () => wrapper.findComponent(GlModal);
  const findPrimaryModalButton = () => wrapper.findByTestId('primary-revoke-btn');

  describe('template', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    describe('revoke button', () => {
      it('displays the revoke button', () => {
        expect(findRevokeButton().exists()).toBe(true);
      });

      it('passes the buttonClass to the button', () => {
        wrapper = createComponent({ buttonClass: 'my-revoke-button' });
        expect(findRevokeButton().classes()).toContain('my-revoke-button');
      });

      it('opens the modal', () => {
        findRevokeButton().trigger('click');
        expect(glModalDirective).toHaveBeenCalledWith(wrapper.vm.modalId);
      });
    });

    describe('modal', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it('renders the revoke modal', () => {
        expect(findModal().exists()).toBe(true);
      });

      it('displays the token name in the modal title', () => {
        expect(findModal().text()).toContain('Revoke testtoken');
      });

      it('displays the token name in the primary action button"', () => {
        expect(findPrimaryModalButton().text()).toBe('Revoke testtoken');
      });

      it('passes the revokePath to the button', () => {
        const revokePath = 'gitlab-org/gitlab-test/-/deploy-tokens/1/revoke';
        wrapper = createComponent({ revokePath });
        expect(findPrimaryModalButton().attributes('href')).toBe(revokePath);
      });
    });
  });
});
