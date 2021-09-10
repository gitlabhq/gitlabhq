import { GlSearchBoxByType } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import HeaderSearchApp from '~/header_search/components/app.vue';
import { ESC_KEY } from '~/lib/utils/keys';
import { MOCK_USERNAME } from '../mock_data';

describe('HeaderSearchApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(HeaderSearchApp);
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findHeaderSearchInput = () => wrapper.findComponent(GlSearchBoxByType);
  const findHeaderSearchDropdown = () => wrapper.findByTestId('header-search-dropdown-menu');

  describe('template', () => {
    it('always renders Header Search Input', () => {
      createComponent();
      expect(findHeaderSearchInput().exists()).toBe(true);
    });

    describe.each`
      showDropdown | username         | showSearchDropdown
      ${false}     | ${null}          | ${false}
      ${false}     | ${MOCK_USERNAME} | ${false}
      ${true}      | ${null}          | ${false}
      ${true}      | ${MOCK_USERNAME} | ${true}
    `('Header Search Dropdown', ({ showDropdown, username, showSearchDropdown }) => {
      describe(`when showDropdown is ${showDropdown} and current_username is ${username}`, () => {
        beforeEach(() => {
          createComponent();
          window.gon.current_username = username;
          wrapper.setData({ showDropdown });
        });

        it(`should${showSearchDropdown ? '' : ' not'} render`, () => {
          expect(findHeaderSearchDropdown().exists()).toBe(showSearchDropdown);
        });
      });
    });
  });

  describe('events', () => {
    beforeEach(() => {
      createComponent();
      window.gon.current_username = MOCK_USERNAME;
    });

    describe('Header Search Input', () => {
      describe('when dropdown is closed', () => {
        it('onFocus opens dropdown', async () => {
          expect(findHeaderSearchDropdown().exists()).toBe(false);
          findHeaderSearchInput().vm.$emit('focus');

          await wrapper.vm.$nextTick();

          expect(findHeaderSearchDropdown().exists()).toBe(true);
        });

        it('onClick opens dropdown', async () => {
          expect(findHeaderSearchDropdown().exists()).toBe(false);
          findHeaderSearchInput().vm.$emit('click');

          await wrapper.vm.$nextTick();

          expect(findHeaderSearchDropdown().exists()).toBe(true);
        });
      });

      describe('when dropdown is opened', () => {
        beforeEach(() => {
          wrapper.setData({ showDropdown: true });
        });

        it('onKey-Escape closes dropdown', async () => {
          expect(findHeaderSearchDropdown().exists()).toBe(true);
          findHeaderSearchInput().vm.$emit('keydown', new KeyboardEvent({ key: ESC_KEY }));

          await wrapper.vm.$nextTick();

          expect(findHeaderSearchDropdown().exists()).toBe(false);
        });
      });
    });
  });
});
