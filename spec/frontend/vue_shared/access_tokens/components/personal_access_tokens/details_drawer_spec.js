import { GlDrawer, GlSprintf, GlButton, GlAlert, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DetailsDrawer from '~/vue_shared/access_tokens/components/personal_access_tokens/details_drawer.vue';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import DateWithTooltip from '~/vue_shared/access_tokens/components/personal_access_tokens/date_with_tooltip.vue';

jest.mock('~/lib/utils/dom_utils');

const SCOPES = ['A', 'B', 'C'];
const TOKEN = {
  name: 'Token 1',
  description: 'Token 1 description',
  lastUsedAt: '2020-02-14T14:23:16.786Z',
  lastUsedIps: ['127.0.0.1', '192.168.0.1', '1.1.1.1'],
  createdAt: '2020-01-14T12:34:56.789Z',
  active: true,
  revoked: false,
  expiresAt: '3099-01-01',
  scopes: SCOPES,
};

describe('Personal access tokens details drawer component', () => {
  let wrapper;

  const createWrapper = ({ token = TOKEN } = {}) => {
    wrapper = shallowMountExtended(DetailsDrawer, {
      propsData: { token },
      stubs: {
        GlDrawer: stubComponent(GlDrawer, { template: RENDER_ALL_SLOTS_TEMPLATE }),
        GlSprintf,
      },
    });
  };

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findTitle = () => wrapper.findByTestId('slot-title');
  const findHeader = () => wrapper.findByTestId('slot-header');
  const findHeaderButtons = () => findHeader().findAllComponents(GlButton);
  const findRotateButton = () => findHeaderButtons().at(0);
  const findRevokeButton = () => findHeaderButtons().at(1);
  const findHeaderAlert = () => findHeader().findComponent(GlAlert);
  const findLabelAt = (index) => wrapper.findAll('dt').at(index);
  const findValueAt = (index) => wrapper.findAll('dd').at(index);

  it('has drawer', () => {
    getContentWrapperHeight.mockReturnValue('123px');
    createWrapper({ token: null });

    expect(findDrawer().props()).toMatchObject({ headerHeight: '123px', zIndex: 252, open: false });
  });

  describe('when there is a token', () => {
    beforeEach(() => createWrapper());

    it('opens drawer', () => {
      expect(findDrawer().props('open')).toBe(true);
    });

    it('emits close event when drawer is closed', () => {
      findDrawer().vm.$emit('close');

      expect(wrapper.emitted('close')).toHaveLength(1);
    });

    it('shows title', () => {
      expect(findTitle().text()).toBe(`Details for 'Token 1'`);
    });

    describe.each`
      name        | findButton          | text        | props
      ${'rotate'} | ${findRotateButton} | ${'Rotate'} | ${{ category: 'primary', variant: 'default' }}
      ${'revoke'} | ${findRevokeButton} | ${'Revoke'} | ${{ category: 'secondary', variant: 'danger' }}
    `('$name button', ({ name, findButton, text, props }) => {
      it('shows button', () => {
        expect(findButton().text()).toBe(text);
        expect(findButton().props()).toMatchObject(props);
      });

      it(`emits ${name} event when clicked`, () => {
        findButton().vm.$emit('click');

        expect(wrapper.emitted(name)).toHaveLength(1);
        expect(wrapper.emitted(name)[0][0]).toBe(TOKEN);
      });
    });

    describe.each`
      index | label            | value
      ${0}  | ${'Name'}        | ${'Token 1'}
      ${1}  | ${'Description'} | ${'Token 1 description'}
      ${6}  | ${'Type'}        | ${'Legacy token'}
    `('$label field', ({ index, label, value }) => {
      it('shows label', () => {
        expect(findLabelAt(index).text()).toBe(label);
      });

      it('shows value', () => {
        expect(findValueAt(index).text()).toBe(value);
      });
    });

    describe.each`
      type            | index | icon           | label          | timestamp                     | token
      ${'expiration'} | ${2}  | ${'expire'}    | ${'Expires'}   | ${'3099-01-01'}               | ${TOKEN}
      ${'last used'}  | ${3}  | ${'hourglass'} | ${'Last used'} | ${'2020-02-14T14:23:16.786Z'} | ${null}
    `('$type field', ({ index, icon, label, timestamp, token }) => {
      it('shows label icon', () => {
        expect(findLabelAt(index).findComponent(GlIcon).props('name')).toBe(icon);
      });

      it('shows label text', () => {
        expect(findLabelAt(index).text()).toBe(label);
      });

      it('shows date with tooltip', () => {
        expect(findValueAt(index).findComponent(DateWithTooltip).props()).toEqual({
          timestamp,
          token,
          icon: null,
        });
      });
    });

    describe('token scopes', () => {
      it('shows label', () => {
        expect(findLabelAt(5).text()).toBe('Token scope');
      });

      describe.each(SCOPES)('for %s scope', (scope) => {
        const index = SCOPES.indexOf(scope);
        const findScopeDiv = () => findValueAt(5).findAll('div').at(index);

        it('shows check icon', () => {
          expect(findScopeDiv().findComponent(GlIcon).props()).toMatchObject({
            name: 'check-sm',
            variant: 'success',
          });
        });

        it('shows scope name', () => {
          expect(findScopeDiv().text()).toBe(scope);
        });
      });
    });

    describe('created field', () => {
      it('shows label icon', () => {
        expect(findLabelAt(7).findComponent(GlIcon).props('name')).toBe('clock');
      });

      it('shows label text', () => {
        expect(findLabelAt(7).text()).toBe('Created');
      });

      it('shows created time', () => {
        expect(findValueAt(7).text()).toBe('January 14, 2020 at 12:34:56 PM GMT');
      });
    });
  });

  it.each`
    type         | props
    ${'expired'} | ${{ active: false }}
    ${'revoked'} | ${{ revoked: true, active: false }}
  `('does not show header buttons for $type token', ({ props }) => {
    createWrapper({ token: { ...TOKEN, ...props } });

    expect(findHeaderButtons()).toHaveLength(0);
  });

  describe('header alerts', () => {
    it('does not show alert for normal token', () => {
      createWrapper();

      expect(findHeaderAlert().exists()).toBe(false);
    });

    it.each`
      type          | tokenProps                     | variant      | message
      ${'expiring'} | ${{ expiresAt: '2020-02-14' }} | ${'warning'} | ${'This token expires soon. If still needed, generate a new token with the same settings.'}
      ${'expired'}  | ${{ active: false }}           | ${'info'}    | ${'This token has expired.'}
      ${'revoked'}  | ${{ revoked: true }}           | ${'info'}    | ${'This token was revoked.'}
    `('shows alert for $type token', ({ tokenProps, variant, message }) => {
      createWrapper({ token: { ...TOKEN, ...tokenProps } });

      expect(findHeaderAlert().props()).toMatchObject({ dismissible: false, variant });
      expect(findHeaderAlert().text()).toBe(message);
    });
  });

  describe('IP usage', () => {
    it('shows IP usage label', () => {
      createWrapper();
      expect(findLabelAt(4).text()).toBe('IP Usage');
    });

    it('shows None when there is no IP usage', () => {
      createWrapper({ token: { ...TOKEN, lastUsedIps: [] } });

      expect(findValueAt(4).text()).toBe('None');
    });

    it('shows IP list when there are IPs', () => {
      createWrapper();
      const divs = findValueAt(4).findAll('div');

      expect(divs.at(0).text()).toBe('127.0.0.1');
      expect(divs.at(1).text()).toBe('192.168.0.1');
      expect(divs.at(2).text()).toBe('1.1.1.1');
    });
  });

  it('shows "No description provided" when token has no description', () => {
    createWrapper({ token: { ...TOKEN, description: null } });

    expect(findValueAt(1).text()).toBe('No description provided.');
  });
});
