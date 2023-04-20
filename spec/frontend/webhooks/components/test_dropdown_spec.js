import { GlDisclosureDropdown } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';

import HookTestDropdown from '~/webhooks/components/test_dropdown.vue';

const mockItems = [
  {
    text: 'Foo',
    href: '#foo',
  },
];

describe('HookTestDropdown', () => {
  let wrapper;

  const findDisclosure = () => wrapper.findComponent(GlDisclosureDropdown);

  const createComponent = (props) => {
    wrapper = mountExtended(HookTestDropdown, {
      propsData: {
        items: mockItems,
        ...props,
      },
      attachTo: document.body,
    });
  };

  it('passes the expected props to GlDisclosureDropdown', () => {
    const size = 'small';
    createComponent({ size });

    expect(findDisclosure().props()).toMatchObject({
      items: mockItems.map((item) => ({
        text: item.text,
      })),
      size,
    });
  });

  describe('clicking on an item', () => {
    beforeEach(() => {
      createComponent();
    });

    it('triggers @rails/ujs data-method=post handling', () => {
      const railsEventPromise = new Promise((resolve) => {
        document.addEventListener('click', ({ target }) => {
          expect(target.tagName).toBe('A');
          expect(target.dataset.method).toBe('post');
          expect(target.getAttribute('href')).toBe(mockItems[0].href);
          resolve();
        });
      });

      wrapper.findByTestId('disclosure-dropdown-item').find('a').trigger('click');

      return railsEventPromise;
    });
  });
});
