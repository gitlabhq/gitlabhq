import { GlDisclosureDropdown } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { getByRole } from '@testing-library/dom';
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
  const clickItem = (itemText) => {
    const item = getByRole(wrapper.element, 'button', { name: itemText });
    item.dispatchEvent(new MouseEvent('click'));
  };

  const createComponent = (props) => {
    wrapper = mount(HookTestDropdown, {
      propsData: {
        items: mockItems,
        ...props,
      },
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

      clickItem(mockItems[0].text);

      return railsEventPromise;
    });
  });
});
