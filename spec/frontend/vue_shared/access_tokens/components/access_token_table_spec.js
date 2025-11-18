import { GlBadge, GlDisclosureDropdown, GlIcon, GlModal, GlTable } from '@gitlab/ui';
import { createTestingPinia } from '@pinia/testing';
import Vue from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import AccessTokenTable from '~/vue_shared/access_tokens/components/access_token_table.vue';
import { useAccessTokens } from '~/vue_shared/access_tokens/stores/access_tokens';

Vue.use(PiniaVuePlugin);

describe('AccessTokenTable', () => {
  let wrapper;

  const pinia = createTestingPinia();
  const store = useAccessTokens();

  const defaultToken = {
    active: true,
    id: 1,
    name: 'My name <super token>',
    createdAt: '2020-01-01',
  };

  const createComponent = (props = {}) => {
    wrapper = mountExtended(AccessTokenTable, {
      pinia,
      propsData: {
        busy: false,
        tokens: [defaultToken],
        ...props,
      },
      stubs: {
        GlModal: stubComponent(GlModal),
      },
    });
  };

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findDisclosure = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDisclosureButton = (index) =>
    findDisclosure().findAll('button.gl-new-dropdown-item-content').at(index);
  const findModal = () => wrapper.findComponent(GlModal);
  const findIcon = (component) => component.findComponent(GlIcon);
  const findTable = () => wrapper.findComponent(GlTable);

  describe('busy state', () => {
    describe('when it is `true`', () => {
      beforeEach(() => {
        createComponent({ busy: true });
      });

      it('has aria-busy `true` in the table', () => {
        expect(findTable().attributes('aria-busy')).toBe('true');
      });

      it('disables the dropdown', () => {
        expect(findDisclosure().props('disabled')).toBe(true);
      });
    });

    describe('when it is `false`', () => {
      beforeEach(() => {
        createComponent();
      });

      it('has aria-busy `false` in the table', () => {
        expect(findTable().attributes('aria-busy')).toBe('false');
      });

      it('enables the dropdown', () => {
        expect(findDisclosure().props('disabled')).toBe(false);
      });
    });
  });

  describe('table headers', () => {
    it('usage header should contain a link and an assistive message', () => {
      createComponent();

      const header = wrapper.findByTestId('header-usage');
      const anchor = header.find('a');
      const assistiveElement = header.find('.gl-sr-only');
      expect(anchor.attributes('href')).toBe(
        '/help/user/profile/personal_access_tokens.md#view-token-usage-information',
      );
      expect(assistiveElement.text()).toBe('View token usage information');
    });
  });

  describe('table cells', () => {
    describe('name cell', () => {
      it('shows the name of the token in bold and description', () => {
        createComponent();

        const field = wrapper.findByTestId('field-name');
        expect(field.text()).toBe('My name <super token>');
        expect(field.classes()).toContain('gl-font-bold');
      });

      it('shows description', () => {
        const tokens = [{ ...defaultToken, description: 'My description' }];
        createComponent({ tokens });

        const field = wrapper.findByTestId('field-description');
        expect(field.text()).toBe('My description');
      });
    });

    describe('status cell', () => {
      describe('when token is active', () => {
        it('shows an active status badge', () => {
          createComponent();

          const badge = findBadge();
          expect(badge.props()).toMatchObject({
            variant: 'success',
            icon: 'check-circle',
          });
          expect(badge.text()).toBe('Active');
        });
      });

      describe('when token is expiring', () => {
        it('shows an expiring status badge', () => {
          const tokens = [
            { ...defaultToken, expiresAt: '2020-07-20' }, // 14 days
          ];
          createComponent({ tokens });

          const badge = findBadge();
          expect(badge.props()).toMatchObject({
            variant: 'warning',
            icon: 'expire',
          });
          expect(badge.text()).toBe('Expiring');
          expect(badge.attributes('title')).toBe('Token expires in less than two weeks.');
        });
      });

      describe('when token is revoked', () => {
        it('shows a revoked status badge', () => {
          const tokens = [{ ...defaultToken, active: false, revoked: true }];
          createComponent({ tokens });

          const badge = findBadge();
          expect(badge.props()).toMatchObject({
            variant: 'neutral',
            icon: 'remove',
          });
          expect(badge.text()).toBe('Revoked');
        });
      });

      describe('when token is expired', () => {
        it('shows an expired status badge', () => {
          const tokens = [{ ...defaultToken, active: false, revoked: false }];
          createComponent({ tokens });

          const badge = findBadge();
          expect(badge.props()).toMatchObject({
            variant: 'neutral',
            icon: 'time-out',
          });
          expect(badge.text()).toBe('Expired');
        });
      });
    });

    describe('scopes cell', () => {
      describe('when it is empty', () => {
        it('shows a hyphen', () => {
          createComponent();

          expect(wrapper.findByTestId('cell-scopes').text()).toBe('-');
        });
      });

      describe('when it is non-empty', () => {
        it('shows a comma-limited list of scopes', () => {
          const tokens = [{ ...defaultToken, scopes: ['api', 'sudo'] }];
          createComponent({ tokens });

          expect(wrapper.findByTestId('cell-scopes').text()).toBe('api, sudo');
        });
      });
    });

    describe('usage cell', () => {
      describe('last used field', () => {
        describe('when it is empty', () => {
          it('shows "Never"', () => {
            createComponent();

            expect(wrapper.findByTestId('field-last-used').text()).toBe('Last used: Never');
          });
        });

        describe('when it is non-empty', () => {
          it('shows a relative date', () => {
            const tokens = [{ ...defaultToken, lastUsedAt: '2020-01-01T00:00:00.000Z' }];
            createComponent({ tokens });

            expect(wrapper.findByTestId('field-last-used').text()).toBe('Last used: 6 months ago');
          });
        });
      });

      describe('last used IPs field', () => {
        describe('when it is empty', () => {
          it('hides field', () => {
            createComponent();

            expect(wrapper.findByTestId('field-last-used-ips').exists()).toBe(false);
          });
        });

        describe('when it is non-empty', () => {
          it('shows a single IP', () => {
            const tokens = [{ ...defaultToken, lastUsedIps: ['192.0.2.1'] }];
            createComponent({ tokens });

            expect(wrapper.findByTestId('field-last-used-ips').text()).toBe('IP: 192.0.2.1');
          });

          it('shows a several IPs', () => {
            const tokens = [{ ...defaultToken, lastUsedIps: ['192.0.2.1', '192.0.2.2'] }];
            createComponent({ tokens });

            expect(wrapper.findByTestId('field-last-used-ips').text()).toBe(
              'IPs: 192.0.2.1, 192.0.2.2',
            );
          });
        });
      });
    });

    describe('lifetime cell', () => {
      describe('expires field', () => {
        describe('when it is empty', () => {
          it('shows "Never until revoked"', () => {
            createComponent();

            const field = wrapper.findByTestId('field-expires');
            const icon = findIcon(field);
            expect(icon.props('name')).toBe('time-out');
            expect(icon.attributes('title')).toBe('Expires');
            expect(field.text()).toBe('Never until revoked');
          });
        });

        describe('when it is non-empty', () => {
          it('shows a relative date', () => {
            const tokens = [{ ...defaultToken, expiresAt: '2021-01-01' }];
            createComponent({ tokens });

            const field = wrapper.findByTestId('field-expires');
            const icon = findIcon(field);
            expect(icon.props('name')).toBe('time-out');
            expect(icon.attributes('title')).toBe('Expires');
            expect(field.text()).toBe('in 5 months');
          });
        });
      });
      describe('created field', () => {
        describe('when it is non-empty', () => {
          it('shows a date', () => {
            const tokens = [{ ...defaultToken, createdAt: '2020-01-01T00:00:00.000Z' }];
            createComponent({ tokens });

            const field = wrapper.findByTestId('field-created');
            const icon = findIcon(field);
            expect(icon.props('name')).toBe('clock');
            expect(icon.attributes('title')).toBe('Created');
            expect(field.text()).toBe('Jan 01, 2020');
          });
        });
      });
    });

    describe('options cell', () => {
      describe('when token is active', () => {
        it('shows the dropdown', () => {
          createComponent();

          expect(findDisclosure().exists()).toBe(true);
        });
      });

      describe('when token is inactive', () => {
        it('hides the dropdown', () => {
          const tokens = [{ ...defaultToken, active: false }];
          createComponent({ tokens });

          expect(findDisclosure().exists()).toBe(false);
        });
      });
    });
  });

  describe('when revoking a token', () => {
    it('makes the modal to appear with correct text', async () => {
      createComponent();
      const modal = findModal();
      expect(modal.props('visible')).toBe(false);
      await findDisclosureButton(1).trigger('click');

      expect(modal.props()).toMatchObject({
        visible: true,
        title: "Revoke the token 'My name <super token>'?",
        actionPrimary: {
          text: 'Revoke',
          attributes: { variant: 'danger' },
        },
        actionCancel: {
          text: 'Cancel',
        },
      });
      expect(modal.text()).toBe(
        'Are you sure you want to revoke the token My name <super token>? This action cannot be undone. Any tools that rely on this access token will stop working.',
      );
    });

    it('confirming the primary action calls the revokeToken method in the store', async () => {
      createComponent();
      findDisclosureButton(1).trigger('click');
      await findModal().vm.$emit('primary');

      expect(store.revokeToken).toHaveBeenCalledWith(1);
    });
  });

  describe('when rotating a token', () => {
    it('makes the modal to appear with correct text', async () => {
      createComponent();
      const modal = findModal();
      expect(modal.props('visible')).toBe(false);
      await findDisclosureButton(0).trigger('click');

      expect(modal.props()).toMatchObject({
        visible: true,
        title: "Rotate the token 'My name <super token>'?",
        actionPrimary: {
          text: 'Rotate',
          attributes: { variant: 'danger' },
        },
        actionCancel: {
          text: 'Cancel',
        },
      });
      expect(modal.text()).toBe(
        'Are you sure you want to rotate the token My name <super token>? This action cannot be undone. Any tools that rely on this access token will stop working.',
      );
    });

    it('confirming the primary action calls the rotateToken method in the store', async () => {
      const tokens = [{ ...defaultToken, expiresAt: '2025-01-01' }];
      createComponent({ tokens });
      findDisclosureButton(0).trigger('click');
      await findModal().vm.$emit('primary');

      expect(store.rotateToken).toHaveBeenCalledWith(1, '2025-01-01');
    });
  });
});
