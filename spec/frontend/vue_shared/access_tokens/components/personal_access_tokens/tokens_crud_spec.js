import { GlBadge, GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { RENDER_ALL_SLOTS_TEMPLATE, stubComponent } from 'helpers/stub_component';
import TokensCrud from '~/vue_shared/access_tokens/components/personal_access_tokens/tokens_crud.vue';
import TokensTable from '~/vue_shared/access_tokens/components/personal_access_tokens/tokens_table.vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import DetailsDrawer from '~/vue_shared/access_tokens/components/personal_access_tokens/details_drawer.vue';

describe('Personal access tokens crud component', () => {
  let wrapper;
  const tokens = [{}, {}];
  const createWrapper = () => {
    wrapper = shallowMountExtended(TokensCrud, {
      propsData: { tokens, loading: false },
      provide: { accessTokenNew: 'new/path' },
      stubs: {
        GlDisclosureDropdown,
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
  });
});
