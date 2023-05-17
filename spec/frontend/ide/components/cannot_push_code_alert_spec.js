import { GlButton, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import CannotPushCodeAlert from '~/ide/components/cannot_push_code_alert.vue';

const TEST_MESSAGE = 'Hello test message!';
const TEST_HREF = '/test/path/to/fork';
const TEST_BUTTON_TEXT = 'Fork text';

describe('ide/components/cannot_push_code_alert', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(CannotPushCodeAlert, {
      propsData: {
        message: TEST_MESSAGE,
        ...props,
      },
      stubs: {
        GlAlert: {
          ...stubComponent(GlAlert),
          template: `<div><slot></slot><slot name="actions"></slot></div>`,
        },
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findButtonData = () => {
    const button = findAlert().findComponent(GlButton);

    if (!button.exists()) {
      return null;
    }

    return {
      href: button.attributes('href'),
      method: button.attributes('data-method'),
      text: button.text(),
    };
  };

  describe('without actions', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows an alert with message', () => {
      expect(findAlert().props()).toMatchObject({ dismissible: false });
      expect(findAlert().text()).toBe(TEST_MESSAGE);
    });
  });

  describe.each`
    action                                                       | buttonData
    ${{}}                                                        | ${null}
    ${{ href: TEST_HREF, text: TEST_BUTTON_TEXT }}               | ${{ href: TEST_HREF, text: TEST_BUTTON_TEXT }}
    ${{ href: TEST_HREF, text: TEST_BUTTON_TEXT, isForm: true }} | ${{ href: TEST_HREF, text: TEST_BUTTON_TEXT, method: 'post' }}
  `('with action=$action', ({ action, buttonData }) => {
    beforeEach(() => {
      createComponent({ action });
    });

    it(`show button=${JSON.stringify(buttonData)}`, () => {
      expect(findButtonData()).toEqual(buttonData);
    });
  });
});
